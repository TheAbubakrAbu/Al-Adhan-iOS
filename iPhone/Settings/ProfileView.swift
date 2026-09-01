import SwiftUI

#if os(iOS)

// MARK: - Statistics engine

/// Everything the profile reports, derived in one pass from stores the app ALREADY keeps. Nothing here
/// is newly tracked and nothing is stored: every number is a function of the prayer tracker and the
/// tasbih counters. That is the whole design rule for this screen - if the app doesn't already know
/// it, the profile doesn't claim it. (The Quran and hadith numbers exist only in Al-Islam; this
/// app's profile is prayer-only.)
///
/// Badges (`AlIslamBadge`, in Achievements.swift) are thresholds ON these numbers, so the cabinet can
/// never claim something the data doesn't support. The one thing that IS stored is the fact that a
/// threshold was crossed - see `AchievementsStore` for why that has to be remembered rather than
/// re-derived.
struct ProfileStats: Equatable {
    // Prayer - all from the tracker's own engine, so the profile and the tracker can never disagree.
    var prayer = PrayerTrackerStats()
    var todayCovered = 0
    var todayTrackable = 0

    // Dhikr
    var dhikrTotal = 0

    var todayPrayerFraction: Double {
        todayTrackable > 0 ? min(1, Double(todayCovered) / Double(todayTrackable)) : 0
    }

    /// Prayer coverage across every countable day - the honest denominator (exempt days are excluded by
    /// the tracker engine, so a paused stretch neither helps nor hurts this).
    var prayerCoverageFraction: Double {
        let possible = prayer.trackedDays * Settings.canonicalObligatoryPrayers.count
        return possible > 0 ? min(1, Double(prayer.totalPrayed) / Double(possible)) : 0
    }

    static func == (l: ProfileStats, r: ProfileStats) -> Bool {
        l.prayer == r.prayer &&
        l.todayCovered == r.todayCovered && l.todayTrackable == r.todayTrackable &&
        l.dhikrTotal == r.dhikrTotal
    }

    /// Cache slot for `current(settings:)`, keyed by a stamp of everything the stats derive
    /// from - the same shape `Settings.trackerStats` uses, and for the same reason: `ProfileSettingsRow`
    /// sits in the Settings list and would otherwise re-derive all of this on every body pass of that
    /// tab, walking the surah maps and the bookmark list each time.
    @MainActor
    private static var cache: (stamp: Int, dhikr: Int, stats: ProfileStats)?

    /// The memoized entry point. Call this, not `compute`, from view code.
    @MainActor
    static func current(settings: Settings) -> ProfileStats {
        // The tasbih store is a separate object with its own storage, so it gets its own cheap
        // component in the key rather than being folded into `profileStatsStamp`.
        let dhikrStamp = TasbihCounters.shared.totalCount
        let stamp = settings.profileStatsStamp

        if let cached = cache, cached.stamp == stamp, cached.dhikr == dhikrStamp {
            return cached.stats
        }

        let stats = compute(settings: settings)
        cache = (stamp, dhikrStamp, stats)
        return stats
    }

    @MainActor
    static func compute(settings: Settings) -> ProfileStats {
        var stats = ProfileStats()

        // Prayer
        stats.prayer = settings.trackerStats
        let slots = settings.trackableSlots(for: Date())
        stats.todayTrackable = slots.isEmpty
            ? Settings.canonicalObligatoryPrayers.count
            : Set(slots.flatMap { Settings.canonicalCoverage(of: $0.nameTransliteration) }).count
        stats.todayCovered = settings.coveredCanonicalPrayers(on: Date()).count

        // Dhikr
        stats.dhikrTotal = TasbihCounters.shared.totalCount

        return stats
    }
}

// MARK: - Entry point

/// The Settings row that opens the profile. Carries live numbers in its caption so the row itself is
/// worth looking at - a streak and a lifetime total answer "how am I doing" without a tap.
struct ProfileSettingsRow: View {
    @ObservedObject private var settings = Settings.shared
    /// Observed so a badge unlocked elsewhere in the app bumps the caption's tally immediately.
    @ObservedObject private var achievements = AchievementsStore.shared

    private var stats: ProfileStats {
        ProfileStats.current(settings: settings)
    }

    private func caption(_ stats: ProfileStats) -> String {
        var parts: [String] = []
        if stats.prayer.currentStreak > 0 {
            parts.append("\(stats.prayer.currentStreak)-day streak")
        }
        if stats.prayer.totalPrayed > 0 {
            parts.append("\(stats.prayer.totalPrayed.formatted(.number)) prayers marked")
        }
        let earned = achievements.unlockedCount(stats)
        if earned > 0 {
            parts.append("\(earned) badge\(earned == 1 ? "" : "s")")
        }
        // Nothing recorded yet: say what the screen is FOR rather than showing three zeros.
        return parts.isEmpty ? "Your prayers and badges" : parts.joined(separator: " · ")
    }

    var body: some View {
        let stats = stats

        NavigationLink(destination: LazyDestination { ProfileView() }) {
            HStack(spacing: 12) {
                AccentIconChip(systemImage: "person.crop.circle.fill", size: 38)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Your Progress")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(caption(stats))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .padding(.vertical, 4)
        }
        .tint(settings.accentColor.color)
    }
}

// MARK: - Profile screen

struct ProfileView: View {
    @ObservedObject private var settings = Settings.shared
    /// Observed so a count tapped on the tasbih screen is reflected the next time this one appears.
    @ObservedObject private var tasbih = TasbihCounters.shared
    @ObservedObject private var achievements = AchievementsStore.shared

    @State private var selectedBadge: AlIslamBadge?
    @State private var badgeFilter: BadgeFilter = .all

    /// The cabinet is large enough now that "what am I close to?" is a different question from "what
    /// have I done?", and one wall of tiles answers neither well.
    private enum BadgeFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case unlocked = "Earned"
        case locked = "In Progress"

        var id: String { rawValue }
    }

    private var stats: ProfileStats {
        ProfileStats.current(settings: settings)
    }

    var body: some View {
        let stats = stats

        ScrollView {
            VStack(spacing: 16) {
                RingHero(stats: stats)
                streakStrip(stats)
                prayerCard(stats)
                dhikrCard(stats)
                badgesSection(stats)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle("Your Progress")
        .navigationBarTitleDisplayMode(.inline)
        .accentWashedBackground()
        .sheet(item: $selectedBadge) { badge in
            BadgeDetailSheet(badge: badge, stats: stats)
        }
    }

    // MARK: Cards

    private func streakStrip(_ stats: ProfileStats) -> some View {
        HStack(spacing: 10) {
            miniStat("\(stats.prayer.currentStreak)", "Current", systemImage: "flame.fill")
            miniStat("\(stats.prayer.bestStreak)", "Best", systemImage: "trophy.fill")
            miniStat("\(stats.prayer.perfectDays)", "Perfect days", systemImage: "checkmark.seal.fill")
        }
    }

    private func prayerCard(_ stats: ProfileStats) -> some View {
        ProfileCard(title: "Prayer", systemImage: "safari.fill") {
            statRow("Prayers marked", value: formatted(stats.prayer.totalPrayed))
            if stats.prayer.totalPrayed > 0 {
                // The share of marked prayers recorded as on time (a late prayer is still prayed, so
                // it stays in "marked" and only moves this percentage).
                statRow("Prayed on time", value: "\(Int((stats.prayer.onTimeFraction * 100).rounded()))%")
            }
            statRow("Days tracked", value: formatted(stats.prayer.trackedDays))
            statRow("Coverage", value: "\(Int((stats.prayerCoverageFraction * 100).rounded()))%")
            if stats.prayer.exemptDayCount > 0 {
                // Named, not hidden: an exempt day is a deliberate pause, and the screen should show
                // that those days were excluded rather than leaving the user to wonder why the
                // denominator looks short.
                statRow("Exempt days", value: formatted(stats.prayer.exemptDayCount))
            }
            if let since = stats.prayer.trackingSince {
                statRow("Tracking since", value: since.formatted(date: .abbreviated, time: .omitted))
            }
        }
    }

    private func dhikrCard(_ stats: ProfileStats) -> some View {
        ProfileCard(title: "Dhikr", systemImage: "circle.hexagonpath.fill") {
            statRow("Counted on the tasbih", value: formatted(stats.dhikrTotal))
        }
    }

    private func badgesSection(_ stats: ProfileStats) -> some View {
        let unlockedCount = achievements.unlockedCount(stats)

        return ProfileCard(title: "Badges", systemImage: "rosette",
                           trailing: "\(unlockedCount) of \(AlIslamBadge.allCases.count)") {
            // The whole cabinet at a glance: one thin accent bar under the header, so "how far along
            // am I overall" is answered before any scrolling through the families.
            ProgressView(value: Double(unlockedCount), total: Double(AlIslamBadge.allCases.count))
                .progressViewStyle(.linear)
                .tint(settings.accentColor.color)
                .padding(.bottom, 2)

            Picker("Show", selection: $badgeFilter) {
                ForEach(BadgeFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 2)

            ForEach(AlIslamBadge.Family.allCases) { family in
                let badges = AlIslamBadge.allCases.filter { $0.family == family }
                let familyUnlocked = achievements.unlockedCount(in: family, stats)
                let shown = badges.filter { badge in
                    switch badgeFilter {
                    case .all:      return true
                    case .unlocked: return achievements.isUnlocked(badge, stats)
                    case .locked:   return !achievements.isUnlocked(badge, stats)
                    }
                }

                // A family with nothing matching the filter drops out entirely rather than leaving a
                // header over an empty grid.
                if !shown.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(family.rawValue.uppercased())
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text("\(familyUnlocked)/\(badges.count)")
                                .font(.caption2.weight(.semibold).monospacedDigit())
                                .foregroundStyle(familyUnlocked == badges.count ? AnyShapeStyle(settings.accentColor.color) : AnyShapeStyle(.secondary))
                        }
                        .padding(.top, 4)

                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
                            spacing: 8
                        ) {
                            ForEach(shown) { badge in
                                Button {
                                    settings.hapticFeedback()
                                    selectedBadge = badge
                                } label: {
                                    BadgeTile(badge: badge, stats: stats)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: Row primitives

    private func statRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer(minLength: 8)

            Text(value)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private func miniStat(_ value: String, _ label: String, systemImage: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: systemImage)
                .font(.caption)
                .foregroundStyle(settings.accentColor.color)

            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundColor(.primary)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .conditionalGlassEffect(rectangle: true, interactive: false)
    }

    private func formatted(_ value: Int) -> String {
        value.formatted(.number)
    }
}

// MARK: - Hero

/// Concentric rings: today's prayers, and lifetime prayer coverage.
///
/// The app deliberately ships ONE accent (accent1/accent2 both resolve to it today - see `AccentColor`),
/// so the rings are separated by weight rather than by hue: outermost is full accent, and each ring
/// inward steps down in opacity. That keeps the hero on-palette under any accent the user picks,
/// including a custom one, instead of inventing colors the rest of the app never uses.
private struct RingHero: View {
    @ObservedObject private var settings = Settings.shared
    let stats: ProfileStats

    /// Rings sweep in from zero each time the screen appears - the fill IS the story here, and the
    /// half-second sweep is what makes it read as progress rather than as static decoration.
    @State private var appeared = false

    private var rings: [(fraction: Double, color: Color, label: String, value: String)] {
        let accent = settings.accentColor.color
        let list: [(Double, Color, String, String)] = [
            (stats.todayPrayerFraction, accent, "Today",
             "\(stats.todayCovered)/\(stats.todayTrackable)"),
            (stats.prayerCoverageFraction, settings.accentColor.accent2.opacity(0.75), "Coverage",
             "\(Int((stats.prayerCoverageFraction * 100).rounded()))%"),
        ]
        return list.map { (fraction: $0.0, color: $0.1, label: $0.2, value: $0.3) }
    }

    var body: some View {
        let rings = rings

        VStack(spacing: 12) {
            ZStack {
                ForEach(Array(rings.enumerated()), id: \.offset) { index, ring in
                    let inset = CGFloat(index) * 22
                    Ring(fraction: appeared ? ring.fraction : 0, color: ring.color, delay: Double(index) * 0.1)
                        .padding(inset)
                }

                // The hole the rings leave is real estate - a quiet on-palette centerpiece keeps the
                // hero from reading as an unfinished donut chart, without inventing another number.
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(settings.accentColor.color.opacity(0.85))
            }
            .frame(width: 150, height: 150)
            .padding(.top, 4)
            .onAppear { appeared = true }
            .onDisappear { appeared = false }

            HStack(spacing: 16) {
                ForEach(Array(rings.enumerated()), id: \.offset) { _, ring in
                    VStack(spacing: 2) {
                        Text(ring.value)
                            .font(.subheadline.weight(.bold).monospacedDigit())
                            .foregroundStyle(ring.color)
                        Text(ring.label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .conditionalGlassEffect(rectangle: true, interactive: false)
    }

    private struct Ring: View {
        let fraction: Double
        let color: Color
        var delay: Double = 0

        var body: some View {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.18), lineWidth: 9)

                // Nothing drawn at zero. A `max(0.001, ...)` floor to keep the trim non-empty renders the
                // round line cap as a stray dot floating at the top of the track - which on a fresh
                // install reads as a rendering glitch rather than as "no progress yet".
                if fraction > 0 {
                    Circle()
                        .trim(from: 0, to: fraction)
                        .stroke(
                            LinearGradient(colors: [color.opacity(0.75), color],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 9, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        // The stagger makes the three rings land as a cascade rather than one blob.
                        .animation(.easeOut(duration: 0.55).delay(delay), value: fraction)
                }
            }
        }
    }
}

// MARK: - Card chrome

private struct ProfileCard<Content: View>: View {
    @ObservedObject private var settings = Settings.shared

    let title: String
    let systemImage: String
    var trailing: String? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                AccentIconChip(systemImage: systemImage, size: 24)

                Text(title)
                    .font(.headline)

                Spacer()

                if let trailing {
                    Text(trailing)
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 2)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .conditionalGlassEffect(rectangle: true, interactive: false)
    }
}

// MARK: - Badge tiles

private struct BadgeTile: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var achievements = AchievementsStore.shared
    let badge: AlIslamBadge
    let stats: ProfileStats

    var body: some View {
        let earned = achievements.isUnlocked(badge, stats)
        let tint = earned ? settings.accentColor.color : Color.secondary

        VStack(spacing: 5) {
            Image(systemName: badge.systemImage)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(earned ? .white : Color.secondary)
                .frame(width: 38, height: 38)
                .background(
                    Circle().fill(
                        earned
                        ? AnyShapeStyle(LinearGradient(
                            colors: [tint.opacity(0.95), tint.opacity(0.6)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        : AnyShapeStyle(Color.secondary.opacity(0.14))
                    )
                )
                // The soft accent glow is what separates "earned" from "colored in" at a glance.
                .shadow(color: earned ? tint.opacity(0.35) : .clear, radius: 5, y: 2)

            Text(badge.title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(earned ? .primary : .secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .frame(height: 26, alignment: .top)

            // A locked tile earns its place by showing the distance left; an earned one has nothing
            // left to say, so the bar is dropped rather than pinned full.
            if !earned {
                ProgressView(value: badge.fraction(stats))
                    .progressViewStyle(.linear)
                    .tint(settings.accentColor.color.opacity(0.7))
                    .frame(height: 3)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(earned ? 0.06 : 0.03))
        )
        // A hairline of accent frames the earned tiles - locked ones stay borderless so the cabinet
        // reads as a field of quiet grey with the earned work lit up.
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(settings.accentColor.color.opacity(earned ? 0.28 : 0), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            if earned {
                Image(systemName: "checkmark.seal.fill")
                    .font(.caption2)
                    .foregroundStyle(settings.accentColor.color)
                    .padding(5)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .opacity(earned ? 1 : 0.75)
    }
}

private struct BadgeDetailSheet: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var achievements = AchievementsStore.shared
    @Environment(\.dismiss) private var dismiss

    let badge: AlIslamBadge
    let stats: ProfileStats

    /// Same appear-sweep as the profile hero: the ring around the badge fills from zero when the
    /// sheet opens, so the distance (or the completed lap) is watched rather than merely stated.
    @State private var appeared = false

    var body: some View {
        let earned = achievements.isUnlocked(badge, stats)
        let (value, goal) = badge.progress(stats)
        let tint = earned ? settings.accentColor.color : Color.secondary

        NavigationView {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(settings.accentColor.color.opacity(0.15), lineWidth: 6)
                        .frame(width: 118, height: 118)

                    // Full lap when earned, partial when not - one shape tells both stories. An
                    // earned badge is pinned full even if the underlying number has since dropped,
                    // so the ring agrees with the seal beneath it.
                    Circle()
                        .trim(from: 0, to: appeared ? (earned ? 1 : badge.fraction(stats)) : 0)
                        .stroke(
                            settings.accentColor.color,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 118, height: 118)
                        .animation(.easeOut(duration: 0.6), value: appeared)

                    Image(systemName: badge.systemImage)
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(earned ? .white : Color.secondary)
                        .frame(width: 92, height: 92)
                        .background(
                            Circle().fill(
                                earned
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [tint.opacity(0.95), tint.opacity(0.6)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                                : AnyShapeStyle(Color.secondary.opacity(0.14))
                            )
                        )
                        .shadow(color: earned ? tint.opacity(0.35) : .clear, radius: 8, y: 3)
                }
                .padding(.top, 20)
                .onAppear { appeared = true }

                VStack(spacing: 6) {
                    Text(badge.family.rawValue.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(settings.accentColor.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(settings.accentColor.color.opacity(0.12)))

                    Text(badge.title)
                        .font(.title3.weight(.bold))

                    Text(badge.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 6) {
                    if earned {
                        // The date is shown only when the ledger actually recorded one. Badges
                        // adopted at the seed (earned before the ledger existed) carry no date, and
                        // the sheet stays silent rather than dating them to the upgrade.
                        if let date = achievements.unlockDate(badge) {
                            Label("Earned \(date.formatted(date: .abbreviated, time: .omitted))",
                                  systemImage: "checkmark.seal.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(settings.accentColor.color)
                        } else {
                            Label("Earned", systemImage: "checkmark.seal.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(settings.accentColor.color)
                        }
                    }

                    // The receipt in the badge's own unit, earned or not - "12,405 of 10,000" is
                    // worth seeing even after the seal.
                    Text("\(value.formatted(.number)) of \(goal.formatted(.number))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)

                    // An unlocked badge whose number has since fallen back below the line (a prayer
                    // unmarked, a bookmark deleted) says so instead of letting the two lines
                    // silently contradict each other.
                    if earned, !badge.isEarned(stats) {
                        Text("Kept - once earned, a badge stays earned.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 40)

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
            .accentWashedBackground()
        }
        .navigationViewStyle(.stack)
        // Half-height where the API exists; iOS 15 gets the full sheet, which the layout already fits.
        .mediumDetentIfAvailable()
    }
}

private extension View {
    @ViewBuilder
    func mediumDetentIfAvailable() -> some View {
        if #available(iOS 16.0, *) {
            self.presentationDetents([.medium])
        } else {
            self
        }
    }
}

#endif
