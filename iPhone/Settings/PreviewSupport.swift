import SwiftUI

enum AlIslamPreviewData {
    /// True only inside an Xcode preview canvas.
    ///
    /// Previews run in-process against the SINGLETONS (`Settings.shared`, `QuranPlayer.shared`), so a
    /// preview that seeds a persisted flag - `nowPlayingExpanded`, `quranPageMode`, the mushaf fold -
    /// writes the real `UserDefaults` of whatever simulator the canvas is using, and that value then
    /// outlives the preview: it leaks into the next preview, and into an ordinary run of the app on
    /// that device. A seeded `quranPageMode` has already cost a launch crash once that way.
    ///
    /// `seedPersisted` below routes such writes through a throwaway suite instead, so a preview can
    /// still show the state it is for without leaving anything behind.
    static var isRunningInPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    /// Writes a persisted flag for the canvas only, remembering what was there first so the value can
    /// be put back. Outside a preview it is a no-op, so a stray call in shipping code is inert.
    ///
    /// The canvas shares one simulator container with ordinary runs of the app on that device, which
    /// is why this is not a plain `set`: an unrestored `quranPageMode` or mushaf-fold flag is a real
    /// state change to the installed app, not just to the preview.
    static func seedPersisted(_ key: String, _ value: Bool) {
        guard isRunningInPreview else { return }
        let defaults = UserDefaults.standard
        if restorePoints[key] == nil {
            restorePoints[key] = defaults.object(forKey: key)
        }
        defaults.set(value, forKey: key)
    }

    /// Puts every flag `seedPersisted` touched back as it was. Hung off the preview's `.onDisappear`.
    static func restoreSeededDefaults() {
        guard isRunningInPreview else { return }
        let defaults = UserDefaults.standard
        for (key, original) in restorePoints {
            if let original { defaults.set(original, forKey: key) } else { defaults.removeObject(forKey: key) }
        }
        restorePoints.removeAll()
    }

    /// Original values of the flags a preview overwrote; `nil` means the key was unset.
    private static var restorePoints: [String: Any?] = [:]

    static let settings: Settings = {
        let settings = Settings.shared
        configure(settings)
        return settings
    }()

    static let namesData = NamesViewModel.shared

    private static func configure(_ settings: Settings) {
        if settings.currentLocation == nil {
            settings.currentLocation = Location(city: "Makkah", latitude: 21.4225, longitude: 39.8262)
        }

        settings.showPrayerInfo = true
        seedPrayerData(on: settings)
    }

    private static func seedPrayerData(on settings: Settings) {
        let prayers = samplePrayers
        let payload = Prayers(
            day: Date(),
            city: settings.currentLocation?.city ?? "Preview City",
            prayers: prayers,
            fullPrayers: prayers,
            setNotification: false
        )

        settings.prayers = payload
        settings.datePrayers = prayers
        settings.dateFullPrayers = prayers
        settings.changedDate = false
        settings.currentPrayer = prayers.first
        settings.nextPrayer = prayers.dropFirst().first
    }

    private static var samplePrayers: [Prayer] {
        let now = Date()
        let calendar = Calendar.current

        func todayAt(hour: Int, minute: Int) -> Date {
            calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now) ?? now
        }

        return [
            Prayer(nameArabic: "الفجر", nameTransliteration: "Fajr", nameEnglish: "Dawn", time: todayAt(hour: 5, minute: 15), image: "sunrise.fill", rakah: "2", sunnahBefore: "2", sunnahAfter: "0"),
            Prayer(nameArabic: "الظهر", nameTransliteration: "Dhuhr", nameEnglish: "Noon", time: todayAt(hour: 12, minute: 30), image: "sun.max.fill", rakah: "4", sunnahBefore: "4", sunnahAfter: "2"),
            Prayer(nameArabic: "العصر", nameTransliteration: "Asr", nameEnglish: "Afternoon", time: todayAt(hour: 15, minute: 45), image: "sun.haze.fill", rakah: "4", sunnahBefore: "0", sunnahAfter: "0"),
            Prayer(nameArabic: "المغرب", nameTransliteration: "Maghrib", nameEnglish: "Sunset", time: todayAt(hour: 18, minute: 20), image: "sunset.fill", rakah: "3", sunnahBefore: "0", sunnahAfter: "2"),
            Prayer(nameArabic: "العشاء", nameTransliteration: "Isha", nameEnglish: "Night", time: todayAt(hour: 20, minute: 0), image: "moon.stars.fill", rakah: "4", sunnahBefore: "0", sunnahAfter: "2")
        ]
    }
}

struct AlIslamPreviewContainer<Content: View>: View {
    private let embedInNavigation: Bool
    private let content: Content

    init(embedInNavigation: Bool = true, @ViewBuilder content: () -> Content) {
        self.embedInNavigation = embedInNavigation
        self.content = content()
    }

    var body: some View {
        previewContent
            .accentColor(AlIslamPreviewData.settings.accentColor.color)
            .tint(AlIslamPreviewData.settings.accentColor.color)
            .environmentObject(AlIslamPreviewData.settings)
            .environmentObject(AlIslamPreviewData.namesData)
    }

    @ViewBuilder
    private var previewContent: some View {
        if embedInNavigation {
            NavigationView {
                content
            }
        } else {
            content
        }
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        Text("Preview Support")
            .padding()
    }
}
