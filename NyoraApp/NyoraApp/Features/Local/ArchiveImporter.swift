import Foundation
import Compression
import UniformTypeIdentifiers

/// Minimal, dependency-free reader for ZIP / CBZ archives, plus honest detection of formats we
/// can't yet handle (CBR/RAR, EPUB).
///
/// CBZ is simply a ZIP whose entries are image files, so we parse the ZIP central directory by
/// hand (no third-party libraries) and extract each stored/deflated entry. Extracted images are
/// written into a managed directory under Application Support so the resulting `LocalManga` is
/// self-contained and needs no security-scoped bookmark.
enum ArchiveImporter {

    /// What kind of file the user picked. We only fully support `.zip` (incl. CBZ).
    enum DetectedFormat {
        case zip            // .zip / .cbz — supported
        case rar            // .cbr / .rar — unsupported (needs an unrar implementation)
        case epub           // .epub — unsupported (needs an XHTML/CSS reader)
        case unknown
    }

    enum ArchiveError: LocalizedError {
        case accessDenied
        case unreadable
        case noImages
        case unsupportedRar
        case unsupportedEpub
        case unsupportedFormat
        case writeFailed

        var errorDescription: String? {
            switch self {
            case .accessDenied:    return "Couldn’t access the selected file."
            case .unreadable:      return "The archive could not be read. It may be corrupt or use an unsupported compression method."
            case .noImages:        return "No image files were found in that archive."
            case .unsupportedRar:  return "CBR/RAR archives aren’t supported yet. Please convert it to CBZ (ZIP) and try again."
            case .unsupportedEpub: return "EPUB books aren’t supported yet. Only image archives (CBZ/ZIP) and folders can be imported."
            case .unsupportedFormat: return "That file type can’t be imported. Use a CBZ/ZIP archive or a folder of images."
            case .writeFailed:     return "Couldn’t save the extracted pages to local storage."
            }
        }
    }

    private static let imageExtensions: Set<String> = ["jpg", "jpeg", "png", "webp", "gif", "heic", "heif", "bmp", "avif", "jxl"]

    // MARK: Format detection

    /// Detect the archive format from the file's magic bytes (preferred) falling back to extension.
    static func detectFormat(of fileURL: URL) -> DetectedFormat {
        // Read the first few bytes for a magic-number sniff.
        var magic = Data()
        if let handle = try? FileHandle(forReadingFrom: fileURL) {
            magic = (try? handle.read(upToCount: 4)) ?? Data()
            try? handle.close()
        }
        let bytes = [UInt8](magic)

        // RAR: "Rar!" 52 61 72 21
        if bytes.starts(with: [0x52, 0x61, 0x72, 0x21]) { return .rar }
        // ZIP family: "PK" 50 4B  (EPUB is also a ZIP, so disambiguate by extension below).
        if bytes.starts(with: [0x50, 0x4B]) {
            if fileURL.pathExtension.lowercased() == "epub" { return .epub }
            return .zip
        }

        switch fileURL.pathExtension.lowercased() {
        case "zip", "cbz": return .zip
        case "cbr", "rar": return .rar
        case "epub":       return .epub
        default:           return .unknown
        }
    }

    // MARK: Public import entry point

    /// Extracted result describing where pages were written and what to title the manga.
    struct ExtractedArchive {
        let title: String
        /// Page paths relative to the managed extraction root for this manga.
        let pageRelativePaths: [String]
        /// Directory name (under the managed "Imports" root) holding the extracted pages.
        let storeDirName: String
    }

    /// Extract a CBZ/ZIP into the managed store. Throws a descriptive error for unsupported formats.
    /// `fileURL` is expected to be a security-scoped URL freshly returned by a document picker.
    static func importArchive(_ fileURL: URL, into root: URL) throws -> ExtractedArchive {
        switch detectFormat(of: fileURL) {
        case .rar:     throw ArchiveError.unsupportedRar
        case .epub:    throw ArchiveError.unsupportedEpub
        case .unknown: throw ArchiveError.unsupportedFormat
        case .zip:     break
        }

        let scoped = fileURL.startAccessingSecurityScopedResource()
        defer { if scoped { fileURL.stopAccessingSecurityScopedResource() } }

        guard let archiveData = try? Data(contentsOf: fileURL, options: .mappedIfSafe) else {
            throw ArchiveError.accessDenied
        }

        let entries: [ZipEntry]
        do {
            entries = try ZipArchive.entries(in: archiveData)
        } catch {
            throw ArchiveError.unreadable
        }

        // Keep only image entries, sorted by their (full) path for natural reading order.
        let imageEntries = entries
            .filter { !$0.isDirectory && imageExtensions.contains(($0.name as NSString).pathExtension.lowercased()) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        guard !imageEntries.isEmpty else { throw ArchiveError.noImages }

        let title = fileURL.deletingPathExtension().lastPathComponent
        let dirName = UUID().uuidString
        let destDir = root.appendingPathComponent(dirName, isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
        } catch {
            throw ArchiveError.writeFailed
        }

        var relativePaths: [String] = []
        // Use zero-padded sequential filenames so on-disk sort order matches reading order
        // regardless of the original (possibly messy) entry names. Preserve each file's extension.
        let width = String(imageEntries.count).count
        for (idx, entry) in imageEntries.enumerated() {
            guard let data = try? ZipArchive.extract(entry, from: archiveData), !data.isEmpty else { continue }
            let ext = (entry.name as NSString).pathExtension.lowercased()
            let name = "\(String(format: "%0\(width)d", idx))." + (ext.isEmpty ? "jpg" : ext)
            let dest = destDir.appendingPathComponent(name)
            do {
                try data.write(to: dest, options: .atomic)
                relativePaths.append(name)
            } catch {
                // Skip an individual bad page rather than failing the whole import.
                continue
            }
        }

        guard !relativePaths.isEmpty else {
            try? FileManager.default.removeItem(at: destDir)
            throw ArchiveError.noImages
        }

        return ExtractedArchive(title: title, pageRelativePaths: relativePaths, storeDirName: dirName)
    }
}

// MARK: - Minimal ZIP central-directory reader

/// One entry parsed from a ZIP central directory.
struct ZipEntry {
    var name: String
    var compressionMethod: UInt16     // 0 = stored, 8 = deflate
    var compressedSize: UInt64
    var uncompressedSize: UInt64
    var localHeaderOffset: UInt64
    var isDirectory: Bool { name.hasSuffix("/") }
}

/// A hand-rolled ZIP reader covering the subset needed for CBZ: the End Of Central Directory
/// record (incl. ZIP64), the central directory file headers, and per-entry extraction of stored
/// (method 0) and deflated (method 8) data via Apple's `Compression` framework.
enum ZipArchive {
    enum ZipError: Error { case notZip, truncated, unsupportedMethod }

    private static let eocdSignature: UInt32 = 0x06054b50
    private static let eocd64Signature: UInt32 = 0x06064b50
    private static let eocd64LocatorSignature: UInt32 = 0x07064b50
    private static let centralFileSignature: UInt32 = 0x02014b50
    private static let localFileSignature: UInt32 = 0x04034b50

    // MARK: Reading the central directory

    static func entries(in data: Data) throws -> [ZipEntry] {
        let eocd = try findEOCD(in: data)
        var (cdOffset, cdCount) = (eocd.cdOffset, eocd.entryCount)

        // ZIP64: if the EOCD has the sentinel values, locate the ZIP64 EOCD record.
        if cdOffset == 0xFFFFFFFF || cdCount == 0xFFFF {
            if let z64 = try? findZip64EOCD(in: data, eocdStart: eocd.recordStart) {
                cdOffset = z64.cdOffset
                cdCount = z64.entryCount
            }
        }

        var entries: [ZipEntry] = []
        var p = Int(cdOffset)
        var i: UInt64 = 0
        while i < cdCount {
            guard p + 46 <= data.count else { break }
            let sig: UInt32 = readLE(data, p)
            guard sig == centralFileSignature else { break }

            let method: UInt16 = readLE(data, p + 10)
            var compSize: UInt64 = UInt64(readLE(data, p + 20) as UInt32)
            var uncompSize: UInt64 = UInt64(readLE(data, p + 24) as UInt32)
            let nameLen = Int(readLE(data, p + 28) as UInt16)
            let extraLen = Int(readLE(data, p + 30) as UInt16)
            let commentLen = Int(readLE(data, p + 32) as UInt16)
            var localOffset: UInt64 = UInt64(readLE(data, p + 42) as UInt32)

            let nameStart = p + 46
            guard nameStart + nameLen <= data.count else { break }
            let nameData = data.subdata(in: nameStart..<(nameStart + nameLen))
            let name = String(data: nameData, encoding: .utf8)
                ?? String(data: nameData, encoding: .isoLatin1) ?? ""

            // Parse the ZIP64 extra field if any sizes/offset are sentinels.
            if compSize == 0xFFFFFFFF || uncompSize == 0xFFFFFFFF || localOffset == 0xFFFFFFFF {
                let extraStart = nameStart + nameLen
                parseZip64Extra(data, start: extraStart, length: extraLen,
                                uncompSize: &uncompSize, compSize: &compSize, localOffset: &localOffset)
            }

            entries.append(ZipEntry(name: name,
                                    compressionMethod: method,
                                    compressedSize: compSize,
                                    uncompressedSize: uncompSize,
                                    localHeaderOffset: localOffset))

            p = nameStart + nameLen + extraLen + commentLen
            i += 1
        }
        return entries
    }

    // MARK: Extraction

    static func extract(_ entry: ZipEntry, from data: Data) throws -> Data {
        let lh = Int(entry.localHeaderOffset)
        guard lh + 30 <= data.count else { throw ZipError.truncated }
        let sig: UInt32 = readLE(data, lh)
        guard sig == localFileSignature else { throw ZipError.notZip }

        let nameLen = Int(readLE(data, lh + 26) as UInt16)
        let extraLen = Int(readLE(data, lh + 28) as UInt16)
        let dataStart = lh + 30 + nameLen + extraLen
        let compSize = Int(entry.compressedSize)
        guard dataStart + compSize <= data.count else { throw ZipError.truncated }

        let compressed = data.subdata(in: dataStart..<(dataStart + compSize))

        switch entry.compressionMethod {
        case 0: // stored
            return compressed
        case 8: // deflate (raw, no zlib header)
            return try inflate(compressed, expectedSize: Int(entry.uncompressedSize))
        default:
            throw ZipError.unsupportedMethod
        }
    }

    /// Raw DEFLATE decompression via Apple's Compression framework.
    private static func inflate(_ input: Data, expectedSize: Int) throws -> Data {
        if input.isEmpty { return Data() }
        // Generous capacity; grow/retry if the expected size was unknown (0) or wrong.
        var capacity = expectedSize > 0 ? expectedSize : max(input.count * 8, 64 * 1024)

        for _ in 0..<6 {
            let result: Data? = input.withUnsafeBytes { (srcRaw: UnsafeRawBufferPointer) -> Data? in
                guard let src = srcRaw.bindMemory(to: UInt8.self).baseAddress else { return nil }
                let dst = UnsafeMutablePointer<UInt8>.allocate(capacity: capacity)
                defer { dst.deallocate() }
                let written = compression_decode_buffer(dst, capacity,
                                                        src, input.count,
                                                        nil, COMPRESSION_ZLIB)
                if written == 0 { return nil }
                // If we exactly filled the buffer and the size was a guess, treat as overflow.
                if written == capacity && expectedSize <= 0 { return nil }
                return Data(bytes: dst, count: written)
            }
            if let result { return result }
            capacity *= 2
        }
        throw ZipError.unsupportedMethod
    }

    // MARK: EOCD location

    private struct EOCD { var entryCount: UInt64; var cdOffset: UInt64; var recordStart: Int }

    private static func findEOCD(in data: Data) throws -> EOCD {
        // EOCD is 22 bytes minimum, with up to a 65535-byte trailing comment. Scan backwards.
        let minLen = 22
        guard data.count >= minLen else { throw ZipError.notZip }
        let maxBack = min(data.count, minLen + 0xFFFF)
        var p = data.count - minLen
        let lowerBound = data.count - maxBack
        while p >= lowerBound {
            if (readLE(data, p) as UInt32) == eocdSignature {
                let count = UInt64(readLE(data, p + 10) as UInt16)
                let offset = UInt64(readLE(data, p + 16) as UInt32)
                return EOCD(entryCount: count, cdOffset: offset, recordStart: p)
            }
            p -= 1
        }
        throw ZipError.notZip
    }

    private static func findZip64EOCD(in data: Data, eocdStart: Int) throws -> EOCD {
        // The ZIP64 EOCD locator sits 20 bytes before the standard EOCD.
        let locStart = eocdStart - 20
        guard locStart >= 0, (readLE(data, locStart) as UInt32) == eocd64LocatorSignature else {
            throw ZipError.notZip
        }
        let z64Offset = Int(readLE(data, locStart + 8) as UInt64)
        guard z64Offset + 56 <= data.count,
              (readLE(data, z64Offset) as UInt32) == eocd64Signature else { throw ZipError.notZip }
        let count: UInt64 = readLE(data, z64Offset + 32)
        let offset: UInt64 = readLE(data, z64Offset + 48)
        return EOCD(entryCount: count, cdOffset: offset, recordStart: z64Offset)
    }

    /// Walk a central-directory extra-field block looking for the ZIP64 (0x0001) tag and fill in
    /// whichever 8-byte values are present (order: uncompressed, compressed, local offset).
    private static func parseZip64Extra(_ data: Data, start: Int, length: Int,
                                        uncompSize: inout UInt64, compSize: inout UInt64,
                                        localOffset: inout UInt64) {
        var p = start
        let end = min(start + length, data.count)
        while p + 4 <= end {
            let tag = Int(readLE(data, p) as UInt16)
            let size = Int(readLE(data, p + 2) as UInt16)
            let body = p + 4
            guard body + size <= end else { break }
            if tag == 0x0001 {
                var q = body
                if uncompSize == 0xFFFFFFFF, q + 8 <= body + size { uncompSize = readLE(data, q); q += 8 }
                if compSize == 0xFFFFFFFF, q + 8 <= body + size { compSize = readLE(data, q); q += 8 }
                if localOffset == 0xFFFFFFFF, q + 8 <= body + size { localOffset = readLE(data, q); q += 8 }
                return
            }
            p = body + size
        }
    }

    // MARK: Little-endian readers

    private static func readLE<T: FixedWidthInteger>(_ data: Data, _ offset: Int) -> T {
        let size = MemoryLayout<T>.size
        var value: T = 0
        guard offset >= 0, offset + size <= data.count else { return 0 }
        for i in 0..<size {
            value |= T(data[data.startIndex + offset + i]) << (8 * i)
        }
        return value
    }
}
