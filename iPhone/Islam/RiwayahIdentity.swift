import SwiftUI

// [Al-Adhan] Companion-only shim. In Al-Islam and Al-Quran these constants live inside
// `Settings.Riwayah` in SettingsQuran.swift, a Quran-domain file this app does not ship.
// The Qiraat guide (QiraatProfiles.swift + the Beliefs "10 Qiraat" pages) only needs the
// naming constants, so just those are mirrored here. Keep the values in lockstep with
// Al-Islam's SettingsQuran.swift; sync_from_islam.sh will not touch this file.

extension Settings {
    enum Riwayah {
        static let hafsTag = ""
        static let hafsLabel = "Hafs an Asim (default)"

        static let shubah = "Shubah an Asim"
        static let khalaf = "Khalaf an Hamzah"
        static let buzzi = "al-Bazzi an Ibn Kathir"
        static let qunbul = "Qunbul an Ibn Kathir"
        static let warsh = "Warsh an Nafi"
        static let qaloon = "Qalun an Nafi"
        static let duri = "ad-Duri an Abi Amr"
        static let susi = "as-Susi an Abi Amr"

        // The 12 remaining riwayat of the Ten Qiraat, extracted from the Islamweb
        // mushaf set (see `BetaQiraatStore`). BETA: machine-extracted, not yet
        // scholar-verified - always gated behind `Settings.betaQiraatEnabled`.
        static let hisham = "Hisham an Ibn Amir"
        static let ibnDhakwan = "Ibn Dhakwan an Ibn Amir"
        static let khallad = "Khallad an Hamzah"
        static let abuHarith = "Abu al-Harith an al-Kisai"
        static let duriKisai = "ad-Duri an al-Kisai"
        static let ibnWardan = "Ibn Wardan an Abi Jafar"
        static let ibnJammaz = "Ibn Jammaz an Abi Jafar"
        static let ruways = "Ruways an Yaqub"
        static let rawh = "Rawh an Yaqub"
        static let ishaq = "Ishaq an Khalaf al-Ashir"
        static let idris = "Idris an Khalaf al-Ashir"

        static let asimTeacher = "Asim"
        static let nafiTeacher = "Nafi"
        static let ibnKathirTeacher = "Ibn Kathir"
        static let abiAmrTeacher = "Abu Amr"
        static let hamzahTeacher = "Hamzah"
        static let ibnAmirTeacher = "Ibn Amir"
        static let kisaiTeacher = "al-Kisai"
        static let abiJafarTeacher = "Abu Jafar"
        static let yaqubTeacher = "Yaqub"
        static let khalafAshirTeacher = "Khalaf al-Ashir"

        static let asimTeacherArabic = "عَاصِم"
        static let nafiTeacherArabic = "نَافِع"
        static let ibnKathirTeacherArabic = "ابنِ كَثِير"
        static let abiAmrTeacherArabic = "أَبُو عَمرٍو"
        static let hamzahTeacherArabic = "حَمزَة"
        static let ibnAmirTeacherArabic = "ابنُ عَامِر"
        static let kisaiTeacherArabic = "الكِسَائِي"
        static let abiJafarTeacherArabic = "أَبُو جَعفَر"
        static let yaqubTeacherArabic = "يَعقُوب"
        static let khalafAshirTeacherArabic = "خَلَفٌ العَاشِر"

        // Where each qiraah imam taught, and when he died (Hijri) - the pickers' secondary line and
        // the Qiraat guide's facts. Cities match the "Companions behind each Qiraah" section.
        static let teacherCity: [String: String] = [
            asimTeacher: "Kufa", nafiTeacher: "Madinah", ibnKathirTeacher: "Makkah",
            abiAmrTeacher: "Basra", hamzahTeacher: "Kufa", ibnAmirTeacher: "Damascus",
            kisaiTeacher: "Kufa", abiJafarTeacher: "Madinah", yaqubTeacher: "Basra",
            khalafAshirTeacher: "Baghdad",
        ]

        static let teacherDiedAH: [String: Int] = [
            asimTeacher: 127, nafiTeacher: 169, ibnKathirTeacher: 120, abiAmrTeacher: 154,
            hamzahTeacher: 156, ibnAmirTeacher: 118, kisaiTeacher: 189, abiJafarTeacher: 130,
            yaqubTeacher: 205, khalafAshirTeacher: 229,
        ]

        /// "Kufa, d. 127 AH" - the qiraah submenus' secondary line for an imam.
        static func teacherDetail(_ teacher: String) -> String? {
            guard let city = teacherCity[teacher], let died = teacherDiedAH[teacher] else { return nil }
            return "\(city), d. \(died) AH"
        }

        static let hafsArabic = "حَفص عَن عَاصِم"
        static let warshArabic = "وَرش عَن نَافِع"
        static let qaloonArabic = "قَالُون عَن نَافِع"
        static let duriArabic = "الدُّورِي عَن أَبِي عَمرٍو"
        static let susiArabic = "السُّوسِي عَن أَبِي عَمرٍو"
        static let buzziArabic = "البَزِّي عَن ابنِ كَثِير"
        static let qunbulArabic = "قُنبُل عَن ابنِ كَثِير"
        static let shubahArabic = "شُعبَة عَن عَاصِم"
        static let khalafArabic = "خَلَف عَن حَمزَة"
        static let hishamArabic = "هِشَام عَن ابنِ عَامِر"
        static let ibnDhakwanArabic = "ابنُ ذَكوَان عَن ابنِ عَامِر"
        static let khalladArabic = "خَلَّاد عَن حَمزَة"
        static let abuHarithArabic = "أَبُو الحَارِث عَنِ الكِسَائِي"
        static let duriKisaiArabic = "الدُّورِي عَنِ الكِسَائِي"
        static let ibnWardanArabic = "ابنُ وَردَان عَن أَبِي جَعفَر"
        static let ibnJammazArabic = "ابنُ جَمَّاز عَن أَبِي جَعفَر"
        static let ruwaysArabic = "رُوَيس عَن يَعقُوب"
        static let rawhArabic = "رَوح عَن يَعقُوب"
        static let ishaqArabic = "إِسحَاق عَن خَلَفٍ العَاشِر"
        static let idrisArabic = "إِدرِيس عَن خَلَفٍ العَاشِر"

        /// Mirrors `Settings.Riwayah.canonicalTag` in Al-Islam's SettingsQuran.swift: folds the
        /// stored spellings this app has shipped over the years onto one tag per riwayah.
        static func canonicalTag(_ stored: String) -> String {
            let raw = stored.trimmingCharacters(in: .whitespacesAndNewlines)
            switch raw {
            case "", "Hafs", "Hafs an Asim", hafsLabel: return hafsTag
            case warsh, "Warsh An Nafi": return warsh
            case qaloon, "Qaloon an Nafi", "Qaloon An Nafi": return qaloon
            case duri, "Ad-Duri an Abi Amr": return duri
            case susi, "As-Susi an Abi Amr": return susi
            case buzzi, "Al-Buzzi an Ibn Kathir": return buzzi
            case qunbul, "Qumbul an Ibn Kathir": return qunbul
            case shubah, "Shu'bah an Asim", "Shu'bah an Aasim", "Shouba an Asim": return shubah
            case khalaf: return khalaf
            default: return raw
            }
        }
    }
}

// The Arabic-alphabet pages name the qalqalah rule where a learner meets the letter. In
// Al-Islam these come from the Quran reader's TajweedRules (a file this app does not ship);
// only the five bounce letters and the legend's qalqalah color are needed here. Keep both
// in lockstep with Al-Islam's TajweedRules.swift.
struct TajweedRules {
    static let qalqalahLetters: Set<Character> = ["ق", "ط", "ب", "ج", "د"]
}

enum TajweedLegendCategory {
    case qalqalah

    var color: Color {
        Color(red: 0.4706, green: 0.8000, blue: 0.9765) // 78CCF9
    }
}

// In Al-Islam this lives in Settings.swift next to the Quran counters it also hashes; this
// app's profile derives only from the prayer tracker, so the stamp reduces to the tracker's
// own inputs (see `trackerStats` in PrayerTrackerView.swift, which hashes the same set).
extension Settings {
    /// A cheap stamp of everything `ProfileStats` derives from, so the profile can skip
    /// recomputing when nothing it reads has changed.
    var profileStatsStamp: Int {
        var hasher = Hasher()
        hasher.combine(prayerTrackerData)
        hasher.combine(trackerExemptDaysData)
        hasher.combine(mensesPauseActive)
        hasher.combine(mensesPauseStartStamp)
        hasher.combine(Calendar.current.startOfDay(for: Date()))
        return hasher.finalize()
    }
}
