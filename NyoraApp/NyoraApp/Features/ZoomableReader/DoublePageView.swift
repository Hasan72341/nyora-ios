import SwiftUI

/// Shows two pages side by side for a landscape "spread". Optional/simple: each side is a
/// `RemoteImage`. Intended to be used only when the device is in landscape and a setting
/// enables double-page spreads. If `rightURL` is nil, only the left page is shown (e.g. a
/// cover or the last odd page of a chapter).
struct DoublePageView: View {
    let leftURL: URL?
    let rightURL: URL?
    var headers: [String: String] = [:]
    /// Reading direction: when right-to-left, the pages are swapped so the "first" page sits
    /// on the right.
    var rightToLeft: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            let first = rightToLeft ? rightURL : leftURL
            let second = rightToLeft ? leftURL : rightURL

            RemoteImage(url: first, headers: headers, contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if second != nil {
                RemoteImage(url: second, headers: headers, contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
