import Foundation
import BackgroundTasks
import UIKit

/// Schedules and runs periodic new-chapter checks in the background using `BGTaskScheduler`.
///
/// Mirrors nyora-android's tracker worker: when granted background runtime the system invokes
/// our `BGAppRefreshTask`, we run `AppModel.checkForUpdates()`, and `UpdateNotifier` posts any
/// new-chapter notifications. We then reschedule for the next interval derived from the
/// `tracker_freq` setting.
///
/// iOS controls exactly when (and whether) background tasks run; the chosen frequency is a
/// lower bound / hint, not a guarantee (surfaced to the user in TrackerSettingsView).
@MainActor
final class BackgroundRefresh {
    static let shared = BackgroundRefresh()
    private init() {}

    /// Must match Info.plist `BGTaskSchedulerPermittedIdentifiers` and the value below.
    static let taskIdentifier = "com.nyora.ios.refresh"

    /// Weak handle so the background task can reach the live app state. Set from NyoraApp.
    private weak var model: AppModel?
    private var didRegister = false

    /// Register the launch handler. Call once, before app finishes launching.
    /// `register(forTaskWithIdentifier:)` must run before the app reports launch completion,
    /// so this is invoked from NyoraApp's init.
    func registerLaunchHandler() {
        guard !didRegister else { return }
        didRegister = true
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier,
            using: nil
        ) { task in
            // The system delivers BGAppRefreshTask; run our check on the main actor.
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            Task { @MainActor in
                await BackgroundRefresh.shared.handle(task: refreshTask)
            }
        }
    }

    /// Connect the AppModel that background runs should query. Call from NyoraApp once the
    /// model exists.
    func attach(model: AppModel) {
        self.model = model
    }

    // MARK: Scheduling

    /// Submit the next background-refresh request, honouring the master switch and frequency
    /// setting. No-op (and cancels any pending request) when checks are disabled or set to
    /// "Manual". Safe to call from foreground transitions (e.g. scenePhase -> background).
    func scheduleIfEnabled() {
        let defaults = UserDefaults.standard
        let trackerEnabled = defaults.object(forKey: "tracker_enabled") as? Bool ?? true
        guard trackerEnabled else {
            cancel()
            return
        }
        guard let interval = nextInterval() else {
            // Manual frequency: no automatic background checks.
            cancel()
            return
        }

        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: interval)
        // Avoid duplicate pending requests.
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.taskIdentifier)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Submission fails on Simulator / when Background App Refresh is disabled; ignore.
        }
    }

    func cancel() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.taskIdentifier)
    }

    /// Earliest interval (seconds) before the next check, derived from `tracker_freq`.
    /// nil means "Manual" (no scheduled checks). Mirrors Android's frequency tiers.
    private func nextInterval() -> TimeInterval? {
        let raw = UserDefaults.standard.string(forKey: "tracker_freq") ?? "1"
        switch raw {
        case "0": return nil                 // Manual
        case "2": return 12 * 60 * 60        // Less frequently  (~12h)
        case "3": return 2 * 60 * 60         // More frequently  (~2h)
        default:  return 6 * 60 * 60         // Default          (~6h)
        }
    }

    // MARK: Execution

    /// Run a single background check. Always reschedules and completes the task, even on
    /// failure/expiration, so the chain continues.
    private func handle(task: BGAppRefreshTask) async {
        // Reschedule immediately so the chain survives even if this run is cut short.
        scheduleIfEnabled()

        let work = Task { @MainActor in
            await runCheck()
        }

        task.expirationHandler = {
            work.cancel()
        }

        await work.value
        task.setTaskCompleted(success: true)
    }

    /// Shared check routine used by the background task. Runs the model's update check (which
    /// itself notifies via UpdateNotifier through the wiring) and updates the badge.
    func runCheck() async {
        guard let model else { return }
        await model.checkForUpdates()
    }

    /// Manually trigger a foreground-equivalent check (e.g. from a debug button). Exposed for
    /// completeness / testing the path without waiting on the scheduler.
    func runCheckNow() {
        Task { @MainActor in await runCheck() }
    }
}
