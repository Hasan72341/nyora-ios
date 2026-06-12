import SwiftUI

/// Incognito mode flag. When enabled, reading progress / history must NOT be recorded.
///
/// Mirrors nyora-android's incognito mode: a single global switch that suppresses any write to
/// the user's reading history. The single write path (`AppModel.recordProgress`) consults this
/// before persisting. Backed by `@AppStorage` so the choice survives relaunches and stays in
/// sync with the SwiftUI Toggle bound to it in settings.
@MainActor
final class IncognitoState: ObservableObject {
    static let shared = IncognitoState()

    /// Persisted incognito switch. Published so views observing the singleton refresh.
    @AppStorage("incognitoMode") var enabled: Bool = false {
        willSet { objectWillChange.send() }
    }

    private init() {}
}
