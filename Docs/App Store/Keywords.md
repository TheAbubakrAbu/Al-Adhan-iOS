# App Store Keywords (ASO)

Keyword research and the App Store Connect **Keywords** field for **Al-Adhan | Prayer Times**.
Keep this in sync whenever a major feature ships (e.g. Prayer Tracker, AI Search).

---

## How the keyword field works

- **100 characters**, comma-separated, entered in App Store Connect (Keywords field, per localization).
- **No spaces after commas** - every space wastes a character. Use `salah,qibla`, never `salah, qibla`.
- **Never repeat** words already in the app **name** or **subtitle** - Apple already indexes those. So do **not** spend keyword characters on: `al`, `adhan`, `prayer`, `times`, or anything in the current subtitle.
- **Apple auto-combines** single keywords into phrases, so `prayer` (from the name) + `tracker` already ranks for "prayer tracker." Don't waste characters on multi-word phrases.
- **Apple stems** singular/plural and common variants - pick one form (`dua`, not `dua,duas`).
- **Alternate spellings matter** - many terms have several common transliterations (`adhan`/`azan`/`athan`, `salah`/`salat`/`namaz`, `masjid`/`mosque`, `dhikr`/`zikr`). These are distinct search terms, so it's worth spending characters on the high-value ones. Note that `adhan` is in the app name, but `azan` and `athan` are **not** - Apple does not treat them as the same word.
- The keyword field is **not** shown to users - it is purely for ranking. The name, subtitle, and description do the human-facing work.

---

## Recommended keyword field (primary)

```
islam,muslim,salah,namaz,azan,athan,qibla,tracker,dua,dhikr,tasbih,masjid,hijri,ramadan,arabic,eid
```

**98 / 100 characters.** Covers the app's biggest search surfaces - the prayer terms Apple can't infer from the name, the tracker, the Qibla, and the everyday-tools terms - while avoiding the name/subtitle words. (2.6.0: `tracker` added for the new Prayer Tracker - it auto-combines with `prayer` from the app name to rank for "prayer tracker," a high-intent, fast-growing search.)

### Why each term

| Keyword | Reason |
|---|---|
| `islam` | Not in the app name, unlike the sibling apps. Broad, highest-volume category term. |
| `muslim` | Broad audience term; auto-combines (e.g. `muslim` + `tracker`, `muslim` + `calendar`). |
| `salah` | The Arabic-transliteration prayer term; a distinct search from "prayer." |
| `namaz` | Urdu/Persian/Turkish word for prayer - large South-Asian and Turkish audience. |
| `azan` | The most common alternate spelling of adhan; not covered by the app name. |
| `athan` | The other common alternate spelling, heavily used in North America. |
| `qibla` | Qibla compass feature; high-intent, moderate competition. |
| `tracker` | New in 2.6.0 (Prayer Tracker); auto-combines with `prayer` from the name. |
| `dua` | Nine dua collections; very high volume, stems toward "duas." |
| `dhikr` | Adhkar collections + the Tasbih counter. |
| `tasbih` | The counter itself; a distinct, high-intent search from `dhikr`. |
| `masjid` | Masjid Locator; also the term most used by the target audience over "mosque." |
| `hijri` | Hijri date, Islamic calendar, and the converter. |
| `ramadan` | Seasonal spike (fasting Live Activity, suhoor/iftar); worth holding year-round for the ranking runway. |
| `arabic` | Arabic alphabet, Tajweed Foundations, and the Arabic fonts. |
| `eid` | Short, cheap, and seasonal - Eid prayer guide and calendar notifications. |

---

## Alternate fields to A/B test

Swap these in when a term underperforms in App Analytics (Search sources) or seasonally.

**Tracker / habit focus** (lean into streaks and insights):
```
islam,muslim,salah,namaz,azan,athan,qibla,tracker,streak,habit,dua,dhikr,tasbih,hijri,ramadan
```

**Learning / convert focus** (lean into the alphabet, tajweed, and beliefs):
```
islam,muslim,salah,namaz,azan,qibla,arabic,alphabet,tajweed,learn,convert,dua,dhikr,pillars,eid
```

**Ramadan season push** (weeks before Ramadan):
```
islam,muslim,salah,namaz,azan,qibla,fasting,iftar,suhoor,eid,tracker,dua,dhikr,tasbih,hijri
```

---

## Full keyword research (by theme)

Ranked roughly by value to this app. Bold = currently in the primary field.

### Prayer
**salah**, **namaz**, **azan**, **athan**, **qibla**, **tracker**, salat, salaat, iqama, prayer reminder, prayer tracker, prayer times, fajr, dhuhr, asr, maghrib, isha, jumuah, tahajjud, witr

### Tracking / habit (2.6.0)
**tracker**, streak, habit, log, insights, heatmap, consistency

### Places
**masjid**, mosque, kaaba, mecca, makkah, madinah, halal, halal food

### Daily worship / tools
**dua**, **dhikr**, **tasbih**, **hijri**, **ramadan**, **eid**, zikr, adhkar, supplication, misbaha, tasbeeh, fasting, iftar, suhoor, calendar, converter, wallpaper

### AI features (2.6.0)
ai (very short, only worth testing in an alternate field - AI Search and Ask AI are described in the description, which is not a ranking input, so `ai` competes on its own)

### Identity / audience
**islam**, **muslim**, islamic, deen, iman, faith, sunni, worship, allah, revert, convert

### Arabic learning
**arabic**, alphabet, letters, tajweed, harakat, tashkeel, learn arabic

### Deliberately excluded
Terms already in the app name (and therefore already indexed): al, adhan, prayer, times. Also excluded: `quran`, `hadith`, `tafsir`, `reciter` - Al-Adhan does not contain the Quran or the Hadith collections, and ranking for them sends users who will be disappointed. Those searches belong to [Al-Islam](https://apps.apple.com/us/app/al-islam-islamic-pillars/id6449729655) and [Al-Quran](https://apps.apple.com/us/app/al-quran-beginner-quran/id6474894373).

---

## Localization (other App Store storefronts)

Each localization has its **own** 100-character keyword field. High-value additions per market:

- **Arabic (ar)**: صلاة, أذان, قبلة, مسجد, دعاء, ذكر, تسبيح, رمضان, هجري, تقويم, عيد, مواقيت الصلاة
- **Urdu / Pakistan, India**: `namaz` is essential (already primary); also `roza`, `ramzan`, `qibla nama`.
- **Turkish (tr)**: `namaz`, `ezan`, `kible`, `oruc`, `dua`, `zikir`, `imsakiye`.
- **Indonesian / Malay (id, ms)**: `sholat`, `adzan`, `kiblat`, `doa`, `dzikir`, `puasa`, `jadwal sholat`.
- **French (fr)**: `priere`, `salat`, `adhan`, `qibla`, `mosquee`, `doua`, `ramadan`, `heures de priere`.

Keep the transliteration variants that match how each region actually types - that is where most of the incremental installs come from.

---

## Companion metadata (for reference)

The keyword field is one of three ranking inputs. The others, already written elsewhere, should stay keyword-rich:

- **App name / subtitle** - carry "Al-Adhan," "Prayer," and "Times" so the keyword field doesn't have to.
- **Description** - see `App Store Description.md`; leads with the prayer tracker, prayer times, and the Qibla.
- **Promotional text** - see `Promotional Text.md`; updated per release, does not affect ranking but drives conversion.

---

## Maintenance checklist

When a major feature ships:
1. Add its highest-intent term to the primary field (trim the weakest current term to stay ≤ 100 chars).
2. Add the feature to `App Store Description.md` and `Promotional Text.md`.
3. Add any new data-source attribution to `CREDITS.md` and the in-app Credits view.
4. After release, watch **App Analytics → Sources → Search** and rotate underperforming keywords using the alternates above.
