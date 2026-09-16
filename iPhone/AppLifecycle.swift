#if os(iOS)
import SwiftUI

/// The one owner of `isIdleTimerDisabled` (Phase 5 step 12): the display stays awake while a Quran
/// reader is on screen (reading, or following a recitation), and only on the full tier. Playback
/// used to own it, which kept the screen on while audio played from any tab.
@MainActor
enum ScreenAwake {
    static var readerVisible = false {
        didSet { apply() }
    }

    static func apply() {
        let wanted = readerVisible && PerformanceProfile.shared.tier != .reduced
        if UIApplication.shared.isIdleTimerDisabled != wanted {
            UIApplication.shared.isIdleTimerDisabled = wanted
        }
    }
}

/// The app's foreground/background orchestration, in one named place.
///
/// This is deliberately NOT in `Settings`: a phase change touches several subsystems (playback
/// persistence, widgets, the in-app adhan player, the fasting Live Activity, Hadith of the Day,
/// location, watch sync), and `Settings` should not know most of them exist.
///
/// ORGANIZED FOR THE COMPANION APPS: every function below is one app domain, whole and
/// self-contained. When this file is copied into Al-Adhan, delete the Al-Quran and Al-Hadith functions
/// (and their calls); into Al-Quran, delete the Adhan and Al-Hadith ones. Nothing in one domain's
/// block depends on another's.
enum AppLifecycle {

    /// Main-actor because it was lifted out of a SwiftUI `.onChange` closure and everything it
    /// touches (players, stores, location) is main-actor state.
    @MainActor
    static func scenePhaseChanged(to phase: ScenePhase) {
        installMemoryWarningPurge()
        adhanScenePhaseChanged(to: phase)
        sharedScenePhaseChanged(to: phase)
    }

    // MARK: - Al-Adhan (prayer times, adhan playback, fasting, location)

    @MainActor
    private static func adhanScenePhaseChanged(to phase: ScenePhase) {
        let settings = Settings.shared

        if phase == .active {
            // An adhan whose moment passed in the last few minutes while the app was CLOSED: play it
            // now, in full and through Silent Mode if that is on. Before `reschedule()`, which only
            // ever looks forward - this is the one path that looks back (Abu, 2026-09-14).
            ForegroundAdhanPlayer.shared.playMissedAdhan()
            // Play the adhan in-app on time while open (the scheduled notification covers the closed
            // case and can be delivered late by the system, especially on Mac/Catalyst).
            ForegroundAdhanPlayer.shared.reschedule()
            // A Live Activity can only be requested from the foreground, so this is the one place that
            // can start the fasting countdown. It no-ops outside Ramadan, and outside the hour before
            // Fajr (suhoor) or Maghrib (iftar).
            FastingActivityController.refresh()
            // Coming back to a stale fix (landed, drove, flew) gets one immediate refresh; the cadence
            // then keeps it loosely current (every ~5 min) for as long as the app stays frontmost -
            // significant-change monitoring can't do this without cell coverage, e.g. on a plane.
            settings.refreshLocationIfStale()
            settings.beginForegroundLocationCadence()
        } else {
            ForegroundAdhanPlayer.shared.stop()
            // A high-accuracy burst pins the GPS. `AdhanView.onDisappear` ends it when you navigate away,
            // but backgrounding the app doesn't disappear the view - without this the burst would run to
            // its 25-second timeout with the screen off.
            settings.endLocationRefinement()
            settings.endForegroundLocationCadence()
        }
    }

    // MARK: - Memory pressure (Phase 5 step 13)

    /// The session caches that are pure speed-ups and rebuild themselves on demand. One observer,
    /// installed on the first scene-phase change (the `NSCache`s already shed on their own).
    /// (Al-Islam purges its Quran reader's tables here too; this app ships no Quran reader.)
    private static var memoryWarningObserver: NSObjectProtocol?

    @MainActor
    private static func installMemoryWarningPurge() {
        guard memoryWarningObserver == nil else { return }
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: .main
        ) { _ in
            Task { @MainActor in MemoryTrim.trimAll() }
        }
    }

    // MARK: - Shared (watch sync - keep in every app that ships a watch companion)

    @MainActor
    private static func sharedScenePhaseChanged(to phase: ScenePhase) {
        guard phase != .active else { return }
        // Send any just-made setting change before the app is suspended, so it can't be lost (and
        // can't be reverted by a stale synced value on the next launch).
        WatchConnectivityManager.shared.flushPendingSync()
    }
}

/// The one owner of the memory-warning trim for the stores the Tilawa port added (Tilawa Guide,
/// Phase 8 step 5): every large store registers here rather than growing an observer of its own.
/// Each call is safe when nothing is loaded.
enum MemoryTrim {
    @MainActor
    static func trimAll() {
        // The Miracles library and its decoded illustrations (a 40-frame animation is ~27 MB).
        MiraclesStore.shared.unload()
        MiracleImageLoader.purgeDecodedImages()
        #if DEBUG
        MemoryFootprint.logLater("memory warning trim", delay: 2)
        #endif
    }
}

#elseif os(watchOS)
import SwiftUI

/// The watch app's foreground/background orchestration - the iPhone `AppLifecycle`'s little sibling,
/// and the same contract: the app root delegates its scene-phase transition HERE in one line, and
/// this is the only place that knows which subsystems care. Deliberately much smaller than the
/// iPhone's: no adhan player, no Live Activity, no Quran-widget snapshots, no daily hadith on the
/// wrist - add a domain section only when the watch actually ships the feature.
enum AppLifecycle {

    @MainActor
    static func scenePhaseChanged(to phase: ScenePhase) {
        let settings = Settings.shared

        if phase == .active {
            // The watch senses its own location (location is never synced from the phone), but its
            // continuous updates stop the moment the app suspends - so after a flight, raising the
            // wrist showed the departure city indefinitely. One immediate one-shot fix on wake, then
            // the same low-frequency cadence the iPhone uses while frontmost.
            settings.refreshLocationIfStale()
            settings.beginForegroundLocationCadence()
        } else {
            settings.endForegroundLocationCadence()
            // (No Quran last-read/khatm flushes here: the reader is an Al-Islam/Al-Quran domain.)
            // Flush any just-made setting change before suspension so it reliably reaches the iPhone.
            WatchConnectivityManager.shared.flushPendingSync()
        }
    }
}
#endif
