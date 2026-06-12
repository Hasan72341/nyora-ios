import Foundation
import UserNotifications
import UIKit

/// Posts local notifications summarising new chapters found during an update check.
///
/// Mirrors nyora-android's `TrackerNotificationHelper`: one per-manga notification (title =
/// manga title, body = "N new chapters") grouped under a thread, plus a summary notification
/// when more than one manga gained chapters. Respects the same settings the
/// "Check for new chapters" / "Notifications" screens write:
///   - `tracker_enabled`        master "Check for new chapters" switch
///   - `tracker_notifications`  "Enable notifications" switch
///   - `tracker_no_nsfw`        "Disable NSFW notifications"
///
/// All work routes through this singleton so both the foreground checker (AppModel) and the
/// background task (BackgroundRefresh) emit identical notifications.
@MainActor
final class UpdateNotifier {
    static let shared = UpdateNotifier()
    private init() {}

    // Notification grouping, matching Android's GROUP_NEW_CHAPTERS thread.
    static let threadIdentifier = "com.nyora.ios.new_chapters"
    static let categoryIdentifier = "NEW_CHAPTERS"
    private static let summaryIdentifier = "com.nyora.ios.new_chapters.summary"

    private let center = UNUserNotificationCenter.current()

    /// One manga that gained chapters, in a notifier-friendly shape (decoupled from AppModel).
    struct ChapterUpdate {
        let mangaId: Int64
        let title: String
        let newCount: Int
        let isNsfw: Bool

        init(mangaId: Int64, title: String, newCount: Int, isNsfw: Bool = false) {
            self.mangaId = mangaId
            self.title = title
            self.newCount = newCount
            self.isNsfw = isNsfw
        }
    }

    // MARK: Permission

    /// Request alert/sound/badge authorisation. Safe to call repeatedly; the system only shows
    /// the prompt once. Returns whether notifications are currently authorised.
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    /// True when the user both authorised notifications at the system level and left the in-app
    /// toggles enabled. Used to decide whether scheduling background checks is worthwhile.
    func isEnabled() async -> Bool {
        guard settingsAllowNotifications else { return false }
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return true
        default: return false
        }
    }

    private var settingsAllowNotifications: Bool {
        let defaults = UserDefaults.standard
        // Defaults match the @AppStorage defaults in TrackerSettingsView (true when unset).
        let trackerEnabled = defaults.object(forKey: "tracker_enabled") as? Bool ?? true
        let notifEnabled = defaults.object(forKey: "tracker_notifications") as? Bool ?? true
        return trackerEnabled && notifEnabled
    }

    private var disableNsfw: Bool {
        UserDefaults.standard.object(forKey: "tracker_no_nsfw") as? Bool ?? false
    }

    // MARK: Posting

    /// Post notifications for the given updates. No-op when nothing is new, notifications are
    /// disabled, or the system hasn't authorised us. NSFW entries are filtered when the user
    /// asked to suppress them.
    func notify(updates: [ChapterUpdate]) async {
        guard settingsAllowNotifications else { return }
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: break
        default: return
        }

        let visible = disableNsfw ? updates.filter { !$0.isNsfw } : updates
        let filtered = visible.filter { $0.newCount > 0 }
        guard !filtered.isEmpty else { return }

        for update in filtered {
            await post(update: update)
        }
        if filtered.count > 1 {
            await postSummary(updates: filtered)
        }

        // Reflect the new-chapter count on the app icon badge (best-effort).
        let total = filtered.reduce(0) { $0 + $1.newCount }
        try? await center.setBadgeCount(total)
    }

    private func post(update: ChapterUpdate) async {
        let content = UNMutableNotificationContent()
        content.title = update.title
        content.body = newChaptersPhrase(update.newCount)
        content.sound = .default
        content.threadIdentifier = Self.threadIdentifier
        content.categoryIdentifier = Self.categoryIdentifier
        content.userInfo = ["mangaId": "\(update.mangaId)"]
        if #available(iOS 15.0, *) { content.interruptionLevel = .active }

        // Stable id per manga so re-checks update the same notification rather than stacking.
        let request = UNNotificationRequest(
            identifier: "new_chapters_\(update.mangaId)",
            content: content,
            trigger: nil // deliver immediately
        )
        try? await center.add(request)
    }

    private func postSummary(updates: [ChapterUpdate]) async {
        let total = updates.reduce(0) { $0 + $1.newCount }
        let content = UNMutableNotificationContent()
        content.title = newChaptersPhrase(total)
        content.body = updates.map { $0.title }.joined(separator: ", ")
        content.sound = .default
        content.threadIdentifier = Self.threadIdentifier
        content.categoryIdentifier = Self.categoryIdentifier
        if #available(iOS 15.0, *) { content.interruptionLevel = .active }

        let request = UNNotificationRequest(
            identifier: Self.summaryIdentifier,
            content: content,
            trigger: nil
        )
        try? await center.add(request)
    }

    private func newChaptersPhrase(_ count: Int) -> String {
        count == 1 ? "1 new chapter" : "\(count) new chapters"
    }
}
