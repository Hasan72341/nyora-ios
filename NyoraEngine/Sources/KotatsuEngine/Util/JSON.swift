import Foundation

/// Thin ergonomic wrapper over `JSONSerialization` output for parsers that consume JSON
/// APIs (MangaDex, etc.). Keeps call sites close to Kotlin's `JSONObject`/`JSONArray`.
@dynamicMemberLookup
struct JSON {
    let raw: Any?

    init(_ raw: Any?) { self.raw = raw }

    subscript(key: String) -> JSON { JSON((raw as? [String: Any])?[key]) }
    subscript(index: Int) -> JSON {
        guard let arr = raw as? [Any], arr.indices.contains(index) else { return JSON(nil) }
        return JSON(arr[index])
    }
    subscript(dynamicMember member: String) -> JSON { self[member] }

    var string: String? { raw as? String }
    var int: Int? { (raw as? Int) ?? (raw as? NSNumber)?.intValue ?? Int((raw as? String) ?? "") }
    var double: Double? { (raw as? Double) ?? (raw as? NSNumber)?.doubleValue }
    var float: Float? { double.map(Float.init) }
    var bool: Bool? { raw as? Bool }
    var array: [JSON] { (raw as? [Any])?.map(JSON.init) ?? [] }
    var dictionary: [String: JSON] {
        (raw as? [String: Any])?.mapValues(JSON.init) ?? [:]
    }
    var exists: Bool { raw != nil }
}
