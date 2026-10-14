import SwiftUI
import WidgetKit

@main
struct AlAdhanApp: App {
    // Plain references, NOT `@StateObject` (Al-Islam's root rule): observing the stores here re-ran
    // this body, the window, the tab host and every mounted tab root on each publish of any of them,
    // and Settings publishes on every GPS fix and countdown tick. The stores are still handed down as
    // environment objects for the views that want them; what the root itself reads (accent, color
    // scheme, first launch, About You) comes from `RootAppearance`, which publishes only when one of
    // those changes.
    private let settings = Settings.shared
    private let namesData = NamesViewModel.shared
    @ObservedObject private var appearance = RootAppearance.shared

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    @State private var isLaunching = true
    // Keeps the splash mounted through its fade-out (see `rootContent`).
    @State private var splashPresented = false
    // The same for the About You question, which follows the splash (or, for everyone who already
    // had the app, follows the launch screen directly).
    @State private var aboutYouPresented = false
    /// True once this launch has shown the splash: About You then knows it is talking to a new
    /// install, the only reader whose suggested settings it may switch on ahead of time.
    @State private var sawSplashThisLaunch = false

    init() {
        LaunchClock.mark("app init")
        #if DEBUG
        LaunchClock.installStallWatch()
        #endif
        // Activate WatchConnectivity so settings sync (and watch app-installed detection) work both ways.
        _ = WatchConnectivityManager.shared

        // The Reminder of the Day corpus (20 KB of xz, a few ms of parse off-main) starts now, before the
        // under-cover tab walk builds the Islam root that reads it, so it never parses on the main thread.
        DailyReminderStore.shared.prewarm()

        if #unavailable(iOS 26.0) {
            // Pre-Liquid-Glass, a scroll view resting at its bottom edge flips the tab bar to its
            // scroll-edge appearance - which iOS leaves fully TRANSPARENT by default, so list content
            // (the Adhan date footer, the Islam rows) collided bare with the tab icons. Pin the standard
            // blurred bar in that state too. iOS 26's Liquid Glass bar handles its own legibility and
            // must not be overridden.
            let bottomEdge = UITabBarAppearance()
            bottomEdge.configureWithDefaultBackground()
            UITabBar.appearance().scrollEdgeAppearance = bottomEdge
        }
    }

    private enum RootStage: Equatable {
        case launch
        case splash
        /// "Which describes you best?" (AboutYouView.swift). A stage rather than a sheet so that every
        /// launch prompt (location, traveling mode, the review card, a tapped notification's
        /// question) waits behind it instead of racing it: `appRevealed` is false until `.main`.
        case aboutYou
        case main
    }

    private var rootStage: RootStage {
        if isLaunching {
            return .launch
        }
        if appearance.firstLaunch { return .splash }
        return appearance.needsAboutYou ? .aboutYou : .main
    }

    private var rootTransitionAnimation: Animation {
        .easeInOut(duration: 0.5)
    }

    var body: some Scene {
        WindowGroup {
            rootContent
                // Every system font in the app is SF Rounded. Views that render a bundled Arabic face opt back
                // out with `arabicFontDesign(custom:)` - see the note in `Globals.swift`.
                .appFontDesign()
                // iPad and Mac read one Dynamic Type step larger (see `regularIdiomTypeBoost`).
                .regularIdiomTypeBoost()
                // Every Toggle in the app breathes: the standard switch with 2pt of vertical padding
                // (user rule), applied once here so no individual row can forget it.
                .toggleStyle(PaddedSwitchToggleStyle())
                .environmentObject(settings)
                .environmentObject(namesData)
                // Accent, tint, color scheme and the shared chrome's `AppearanceEnvironment`, live. Without
                // this every `\.appearance` reader (glass, row backgrounds, icon chips, section pills) sits on
                // the key's one-time launch snapshot, so an accent change only showed after a restart.
                .appearanceEnvironment()
                .appReviewPrompt()
                // Set ABOVE (outside) `.appReviewPrompt()` too, or its `@Environment(\.appRevealed)`
                // reads the key's default (true): the copy inside `rootContent` sits BELOW the review
                // modifier in the tree, and environment only flows down - the launch-cover gate on the
                // review sheet was silently inert without this.
                .environment(\.appRevealed, rootStage == .main)
                // Watches the stores the badges are thresholds on. The banner itself is NOT hosted
                // here - it lives in its own window above the app (see `AchievementBannerPresenter`)
                // so it can still be seen when the thing that earned it happened inside a sheet.
                .achievementTracking()
                // The same shape for the playing adhan: its banner is its own window too, so the
                // recording can be stopped from any tab and from on top of any sheet.
                .adhanBannerHost()
                // No `.onAppear { settings.fetchPrayerTimes() }` here: `AdhanView.onAppear` runs the launch
                // fetch a frame later (it is the initial tab), so this was a second full recompute on
                // the first-paint path.
                //.statusBarHidden()
        }
        // No `.onChange` refreshes for settings here: each setting's own didSet performs its side
        // effects (`accentColor` and `hijriOffset` repaint widgets from Settings; `prayerCalculation`,
        // `travelingMode`, and `hanafiMadhab` recompute on every write path already - a blanket refresh
        // here would run a SECOND full forced fetch per flip and re-run the automatic detection with
        // checks ON right after the change, the exact override/spam bug the old one-shot flags papered
        // over). Phase transitions delegate to the one place that orchestrates them.
        .onChange(of: scenePhase) { phase in
            AppLifecycle.scenePhaseChanged(to: phase)
        }
    }

    @ViewBuilder
    private var rootContent: some View {
        ZStack {
            // Keep the tabs mounted from the very first frame - even while the launch/splash screen still covers
            // the screen - so each tab can realize its view tree behind that cover instead of on the first
            // visible tap (see `MainTabView`). The launch/splash screens overlay on top and fade out to reveal it.
            MainTabView(isCovered: rootStage != .main)
                // Always opaque underneath the covers. The launch/splash screens are opaque and simply fade
                // themselves out (below) to reveal it - a clean single-layer dissolve, no mid-transition dip.
                .zIndex(1)

            // Above the tabs but below the covers: a letter / name blown up to fill the screen. It lives
            // here (rather than on the row that opened it) so it can sit over the tab bar and fade in as a
            // plain overlay instead of a system sheet.
            FocusOverlayHost()
                .zIndex(1.5)

            if rootStage == .launch {
                LaunchScreen(isLaunching: $isLaunching)
                    .zIndex(3)
                    .transition(.opacity)
            }

            // The splash fades via an explicit `.opacity` (kept mounted through the fade), NOT a removal
            // `.transition`: SplashScreen wraps a NavigationView, which doesn't animate SwiftUI removal
            // transitions - it just snaps. A plain opacity animation on the hosted content works, giving the
            // splash → main hand-off a real cross-fade. It's unmounted a beat after the fade completes.
            if splashPresented {
                SplashScreen()
                    .opacity(rootStage == .splash ? 1 : 0)
                    .allowsHitTesting(rootStage == .splash)
                    .zIndex(2)
            }

            // About You sits UNDER the splash and the launch screen, opaque from the moment it is
            // mounted, so whichever cover precedes it dissolves onto it (a view that faded IN here
            // would show the tabs through two half-transparent covers mid-way). It fades only on its
            // own way out, by the same explicit opacity as the splash and for the same reason.
            if aboutYouPresented {
                AboutYouView(isNewInstall: sawSplashThisLaunch)
                    .opacity(rootStage == .main ? 0 : 1)
                    .allowsHitTesting(rootStage == .aboutYou)
                    .zIndex(1.8)
            }
        }
        .animation(rootTransitionAnimation, value: rootStage)
        // The tabs are mounted (and side-effecting views like AdhanView build) before the cover lifts; let them
        // hold user-facing prompts until we're actually on screen.
        .environment(\.appRevealed, rootStage == .main)
        // Seed the LIVE mirror at mount: `onChange` below only fires on transitions, and the mirror
        // defaults to `true` - without this, the launch window would read as revealed.
        .onAppear {
            AppReveal.revealed = (rootStage == .main)
            // Mounted from the first frame when it is going to be needed, under the launch cover, so
            // the cover never lifts onto the tabs for a frame before the question arrives.
            if appearance.needsAboutYou { aboutYouPresented = true }
        }
        .onChange(of: rootStage) { stage in
            // Keep the LIVE mirror in sync for escaping tasks (see `AppReveal`) - the environment value
            // above only reaches view bodies, and a frozen captured copy is what broke the review prompt.
            AppReveal.revealed = (stage == .main)
            if stage == .splash { sawSplashThisLaunch = true }
            if stage == .aboutYou {
                aboutYouPresented = true
            } else if aboutYouPresented {
                // Answered or skipped: its opacity is animating to 0 above - unmount after the fade.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    if rootStage != .aboutYou { aboutYouPresented = false }
                }
            }
            if stage == .splash {
                splashPresented = true
            } else if splashPresented {
                // Leaving the splash: its opacity is animating to 0 above - unmount once that fade is done.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    if rootStage != .splash { splashPresented = false }
                }
            }
        }
    }
}

private struct MainTabView: View {
    // Deliberately NOT observing Settings: this body reads none of it, and an `@ObservedObject`
    // subscription re-evaluated the ENTIRE TabView (all three tabs) on every publish - Settings
    // publishes on every GPS fix and countdown tick. `warmUnderCover` reaches the singleton directly.
    private let settings = Settings.shared
    /// True while a launch/splash screen still covers the tabs (drives the under-cover warm below).
    let isCovered: Bool

    private enum AppTab: String, Hashable { case adhan, islam, settings }

    #if DEBUG
    /// Headless tab switching for verification runs: `Settings`' `-settingsProbe` posts this with the
    /// tab's raw value ("adhan") so a probe can change a setting on one tab and then LOOK at another -
    /// the only way to reproduce cross-tab staleness without tap tooling.
    ///
    /// `Settings.swift` syncs down from Al-Islam and has always POSTED this; the observer lives in the
    /// app entry point, which is a per-app variant the sync keeps as ours, so nothing was listening
    /// here and every `tab=` step was a silent no-op. Same shape as the `-auditPacks` hook.
    ///
    /// A `tab=quran` or `tab=hadith` step names a tab this app does not ship, so `AppTab(rawValue:)`
    /// returns nil and the step is ignored rather than mis-selecting one.
    static let debugSwitchTabNotification = Notification.Name("AlIslamDebugSwitchTab")
    #endif

    // Adhan is the initial tab and builds first. The other two are realized during `warmUnderCover()` -
    // briefly selected so `TabView` builds and RETAINS their view trees, then we settle on the opening
    // tab. All of this happens behind the launch cover, and the launch screen waits for it to finish (see
    // `LaunchWarmup`) before it reveals - so the user only ever sees a fully-built opening tab. No visible
    // tab flip, no first-tap stall.
    @State private var selectedTab: AppTab = .adhan
    @State private var didWarm = false
    /// The opening Adhan tab's content waits for the launch cover's first frame, like the warm walk
    /// below: built in the same pass, it held that frame (and the cover's animation task) back
    /// (Al-Islam's Quality Guide F1). Behind an opaque cover either way; true from the start when
    /// nothing covers the tabs.
    @State private var initialTabMounted: Bool

    init(isCovered: Bool) {
        self.isCovered = isCovered
        _initialTabMounted = State(initialValue: !isCovered)
    }

    var body: some View {
        #if DEBUG
        let _ = LaunchClock.markOnce("main tab view: first body")
        #endif
        tabs
            #if DEBUG
            .onAppear { LaunchClock.markOnce("main tab view: on appear") }
            .onReceive(NotificationCenter.default.publisher(for: Self.debugSwitchTabNotification)) { note in
                if let raw = note.object as? String, let tab = AppTab(rawValue: raw) {
                    selectedTab = tab
                }
            }
            #endif
            // (A tapped prayer notification's "Did you pray X?" is not hosted here: it is presented
            // over whatever is on screen by `PrayerNotificationPrompt`, AppDelegate.swift.)
            // A Control Center control lands on the Adhan tab; the tab's own `.onReceive` raises the
            // Qibla sheet from there. `.tab` has nothing to push, so it clears itself here.
            .onReceive(AppNavigation.shared.$pendingAdhan) { target in
                guard let target else { return }
                selectedTab = .adhan
                if case .tab = target { AppNavigation.shared.pendingAdhan = nil }
            }
            // iPad: a Dynamic Type change inside the tab bar's selection animation is the UIKit hang
            // DynamicTypeCoalescer.swift describes; the coalescer holds one until the switch settles.
            .onChange(of: selectedTab) { _ in
                DynamicTypeCoalescer.noteTabSelectionChanged()
            }
            // A Reminder of the Day card's "Open" (or About You's "Start Learning") lands on the Islam
            // tab; the Islam tab's own `.onReceive` pushes the resource from there. `.tab` has nothing
            // to push, so it clears itself here.
            .onReceive(AppNavigation.shared.$pendingIslam) { target in
                guard let target else { return }
                selectedTab = .islam
                if case .tab = target { AppNavigation.shared.pendingIslam = nil }
            }
            // Launch warmups, one .task per app domain (like AppLifecycle's sections).
            // Shared: the tab walk behind the launch cover.
            .task { await warmUnderCover() }
            // Al-Adhan: an adhan whose moment passed in the last few minutes while the app was
            // closed. The scene-phase hook cannot cover this one - see the function's comment.
            .task { await AppLifecycle.playMissedAdhanAtLaunch() }
            #if DEBUG
            // "-askAITextProbe": Ask AI's pure text functions on the audit's failing inputs (AskAIText.swift).
            .task { AskAITextProbe.runIfRequested() }
            #endif
            // POST-REVEAL: the Islam article corpus, inflated off-main once the cover has lifted (it used
            // to fire from the Islam tab root's own task, which the under-cover walk realizes, so it
            // landed inside the launch window every time).
            .task {
                await AppReveal.waitUntilRevealed()
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                guard !Task.isCancelled else { return }
                IslamArticleSearchModel.prewarm()
            }
    }

    /// Build + retain every tab behind the launch cover, settle on the opening tab, then signal
    /// `LaunchWarmup` that the UI is ready to reveal. Runs once. If we were mounted already-uncovered
    /// (not a cold launch), there's nothing to hide, so we just mark warm immediately.
    @MainActor
    private func warmUnderCover() async {
        guard !didWarm else { return }
        didWarm = true

        guard isCovered else { LaunchWarmup.shared.markWarm(); return }

        // Never before the cover's own first frame: a tab build in the same run-loop pass would sit
        // between the window and the icon.
        await LaunchWarmup.shared.waitUntilCoverUp(maxWaitNanos: 1_000_000_000)
        try? await Task.sleep(nanoseconds: 16_000_000)
        if Task.isCancelled { LaunchWarmup.shared.markWarm(); return }

        // One frame between tabs, not a settle: a selection change realizes the tab synchronously in the
        // next run-loop pass (which is what a sleep's resume waits behind anyway). Low Power Mode /
        // low-memory devices skip the walk: the two tabs realize on their first real visit instead.
        if !AppPerformance.shouldAvoidBroadPrewarm {
            for tab in [AppTab.islam, .settings] {
                selectedTab = tab
                try? await Task.sleep(nanoseconds: 16_000_000)
            }
        }
        LaunchClock.mark("tabs walked")

        // Back on the landing tab; let it become the rendered tab again before the reveal.
        selectedTab = launchTab
        try? await Task.sleep(nanoseconds: 80_000_000)

        LaunchWarmup.shared.markWarm()
    }

    /// The tab the app lands on after the under-cover warm: Adhan ("Open the App On" is Al-Islam's
    /// alone, `LaunchTab.isOffered`, so the stored choice stays Adhan here). A DEBUG launch argument
    /// lets UI automation land straight on a tab it wants to exercise (there is no other way to drive
    /// the simulator's tab bar from a test harness without an XCUITest target).
    private var launchTab: AppTab {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-launchTabIslam") { return .islam }
        if ProcessInfo.processInfo.arguments.contains("-launchTabSettings") { return .settings }
        #endif
        return settings.launchTab == .islam ? .islam : .adhan
    }

    @ViewBuilder
    private var adhanTab: some View {
        if initialTabMounted {
            AdhanView()
        } else {
            Color.clear
                .task {
                    await LaunchWarmup.shared.waitUntilCoverUp(maxWaitNanos: 1_000_000_000)
                    initialTabMounted = true
                }
        }
    }

    @ViewBuilder
    private var tabs: some View {
        if #available(iOS 18.0, *) {
            TabView(selection: $selectedTab) {
                Tab("Adhan", systemImage: "mecca", value: AppTab.adhan) {
                    adhanTab
                }

                Tab("Islam", systemImage: "moon.stars", value: AppTab.islam) {
                    IslamView()
                }

                Tab("Settings", systemImage: "gearshape", value: AppTab.settings) {
                    SettingsView()
                }
            }
        } else {
            TabView(selection: $selectedTab) {
                adhanTab
                    .tabItem {
                        Image(systemName: "safari")
                        Text("Adhan")
                    }
                    .tag(AppTab.adhan)

                IslamView()
                    .tabItem {
                        Image(systemName: "moon.stars")
                        Text("Islam")
                    }
                    .tag(AppTab.islam)

                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape")
                        Text("Settings")
                    }
                    .tag(AppTab.settings)
            }
        }
    }
}
