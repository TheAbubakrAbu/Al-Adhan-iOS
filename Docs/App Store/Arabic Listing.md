# App Store Arabic Listing

The **Arabic** localization of the App Store listing for **Al-Adhan | Prayer Times**. In App Store Connect,
add the Arabic localization, then fill Name and Subtitle under App Information and the other four fields on
the version page.
People whose device is set to Arabic see this listing instead of the English one. In the Arabic interface the
app calls itself الأذان, and its tabs are الأذان، الإسلام and الإعدادات; the listing uses the same words.
Modeled on Al-Islam's `Docs/App Store/Arabic Listing.md`, whose style and glossary this file follows.

| Field | Limit | Editable without a new version? |
|---|---|---|
| Name | 30 | No |
| Subtitle | 30 | No |
| Keywords | 100 | No |
| Promotional Text | 170 | Yes |
| Description | 4,000 | No |
| What's New | 4,000 | No |

## Guidelines

- **Counts are Python `len()`** of the exact text inside each code block (the bold tally lines are for this
  file, not the store). Re-check after any edit:
  `python3 -c 'import re;f=chr(96)*3;t=open("Docs/App Store/Arabic Listing.md").read();[print(len(b)) for b in re.findall(f+"\n(.*?)\n"+f,t,re.S)]'`
- **Modern Standard Arabic as Apple's own Arabic pages read it**, with the respectful register (النبي صلى الله عليه وسلم). The honorific is always spelled out: App Store Connect rejects the one-glyph ligature (U+FDFA) as an invalid character.
  Feature names are the labels the app shows (Al-Islam's `Resources/Localizable.xcstrings`, which Al-Adhan
  receives in its sync; see the glossary below).
- **Inside a sentence the app is تطبيق الأذان.** A bare الأذان in running text reads as the call to prayer
  itself; it stands alone only as the name, as the tab, or inside a quoted label.
- **No em dash, and no spaced hyphen used as a dash.** Use a colon, the Arabic comma ، or a new sentence.
  A leading "- " bullet is fine; the English fields use the same.
- **Arabic punctuation** (، ؛ ؟) and Arabic-Indic digits (٢١، ١٢٣) in the store text. No version numbers.
- **Brand names stay Latin:** Apple, Siri, Apple Watch, Apple Intelligence, iPhone, iPad, Mac, iOS; so do
  PDF, CSV and OC Ummah.
- **No harakat in the name, subtitle or keywords.** A shadda is a character of its own and nobody types one
  in a search. The description and notes may use them where the app's own label does (متتبّع الصلاة).
- **Only what the English listing claims.** Every feature named here is in Al-Adhan's English
  `App Store Description.md` or `Whats New.md`. Al-Adhan has no Quran reader and no Hadith tab: no Quran or
  hadith features and no Quran or hadith search terms (the English `Keywords.md` excludes them too).
- **Be honest about what is still English:** the in-depth articles of the Islam tab (Proving Islam, the
  How-To Guides, the pillars and the miracles libraries among them), and AI search by meaning, which matches
  English phrases only.
- **No scripture quoted.** No Quranic text and no hadith presented as the Prophet's words.
- Keep in sync with the English docs: `App Store Description.md`, `Keywords.md`, `Promotional Text.md` and
  `Whats New.md`. When an English field changes for a feature, change the Arabic one in the same pass.

## 1. Name

Names are unique across the store, so a bare الأذان will not be accepted. Each option keeps الأذان first,
then a short descriptor after a separator, as the English name does with "|".

**Recommended:**

```
الأذان | مواقيت الصلاة
```

**22 / 30 characters.**

The English name word for word. مواقيت الصلاة is the most searched prayer phrase in Arabic, and the
subtitle carries the Qibla and the Hijri calendar.

**Alternate A:**

```
الأذان | أوقات الصلاة
```

**21 / 30 characters.**

The other common phrasing. With it, swap اوقات in the keyword field for مواقيت.

**Alternate B:**

```
الأذان | مواقيت الصلاة، القبلة
```

**30 / 30 characters.**

Puts the Qibla in the name and sits exactly at the limit. Pair it with a subtitle that does not repeat
القبلة, for example التقويم الهجري، الأذكار، رمضان (30 characters), and in the keyword field replace رمضان
(now in the subtitle) with اتجاه.

## 2. Subtitle

**Recommended** (with the recommended name):

```
اتجاه القبلة، التقويم الهجري
```

**28 / 30 characters.**

Two phrases people type whole: اتجاه القبلة for the compass, التقويم الهجري for the Hijri calendar, its
events and Ramadan. A comma between them, so no word carries an attached و.

**Alternate:**

```
متتبع الصلوات، القبلة، الأذكار
```

**30 / 30 characters.**

Leads with the prayer tracker, as the English description does. No shadda (the app's label is متتبّع
الصلاة; the plural keeps الصلاة from repeating the name). With it, the keyword field loses the Hijri
calendar's phrase: replace بوصلة with تقويم so "تقويم هجري" still matches.

## 3. Keywords

Written for the recommended name and subtitle. No word repeats one of theirs (الأذان، مواقيت، الصلاة،
اتجاه، القبلة، التقويم، الهجري); as in Al-Islam's field, a word without ال or without its hamza is a search
term of its own. If an alternate ships, re-check that and swap in the words it dropped.

```
اذان,اوقات,صلاة,قبلة,هجري,اذكار,دعاء,تسبيح,حصن,مسلم,رمضان,امساكية,عيد,مسجد,حلال,منبه,الفجر,مكة,بوصلة
```

**100 / 100 characters.**

Why these terms:
- **اذان، اوقات، صلاة:** أذان as it is usually typed, without the hamza; اوقات pairs with the name's الصلاة
  for "اوقات الصلاة", searched as often as مواقيت الصلاة; صلاة without ال for "صلاة الفجر", "صلاة الجمعة"
  and the like.
- **قبلة، بوصلة، مكة:** the subtitle's word without ال, "بوصلة القبلة", and "اتجاه مكة", which many type
  instead of القبلة (the At a Glance board shows the distance to Makkah).
- **هجري، رمضان، امساكية، عيد:** "تقويم هجري"; the Ramadan Live Activity for suhoor and iftar; the prayer
  calendar of the next thirteen months, exportable as PDF, which serves as an imsakiyah; the Islamic
  calendar's Eid dates and their notifications.
- **اذكار، دعاء، تسبيح، حصن، مسلم:** the adhkar and dua collections and the tasbih counter; with حصن, مسلم
  covers "حصن المسلم" and also matches the audience.
- **مسجد، حلال:** the Masjid and Halal Food locators.
- **منبه، الفجر:** "منبه الصلاة" and "اذان الفجر", the alarm searches that adhan notifications answer.

Left out for room, to rotate in from App Analytics: الاذان، اسلامي، صيام، سحور، افطار، سبحة، متتبع، قصر (for
"قصر الصلاة", Traveling Mode). Deliberately excluded, as in the English `Keywords.md`: قرآن، تفسير، حديث،
قارئ, and تجويد (the Islam tab has Tajweed Foundations, but no Quran reader, so most people who search it
would be disappointed); those searches belong to Al-Islam and Al-Quran. If Apple's Arabic search turns out to
fold the hamza (أ to ا) or to ignore ال, اذان، صلاة، قبلة and هجري are redundant and are the first to swap.

## 4. Promotional Text

Leads with the Arabic interface. Update it with the next release like the English one.

```
جديد: واجهة عربية كاملة من اليمين إلى اليسار، واسأل Siri بالعربية عن الصلاة القادمة. مواقيت الصلاة والقبلة ومتتبّع الصلاة في تطبيق مجاني بلا إعلانات.
```

**149 / 170 characters.**

## 5. Description

An Arabic rendering of `App Store Description.md`, section for section, with the English ALL-CAPS headers as
short Arabic headings on their own lines. Three differences from the English: the "Prayer Sky widget" is
written as sky widgets (no widget carries that exact name; they are Prayer Countdown Sky, Current Prayer Sky
and the rest); Tajweed Foundations joins the learning line (it is in the English 2.6.0 notes and on the Islam
tab); and a line on the Arabic interface opens على طريقتك, as in Al-Islam's listing.

```
تطبيق الأذان رفيقك في صلاتك كل يوم، سواء نشأت على الإسلام أو اعتنقته حديثًا أو جئت تتعرّف عليه. مواقيت الصلاة ومتتبّع الصلاة والقبلة والتقويم الهجري والبحث بالذكاء الاصطناعي على جهازك، في تطبيق واحد بسيط: مجاني تمامًا، بلا إعلانات، ويحفظ خصوصيتك.

متتبّع الصلاة
- علّم كل صلاة بضغطة، مع سلسلة الأيام والأيام المثالية وتقويم ملوّن يُظهر التزامك حسب اليوم والأسبوع والشهر والسنة.
- تُحتسب صلاة الجمعة وصلوات الجمع في السفر كما ينبغي، وأيام الحيض والنفاس لا تقطع سلسلة أيامك أبدًا.
- اضغط على أي إشعار صلاة لتجيب عن سؤال «هل صلّيت؟»، ودع «وضع التذكير المتكرر» يذكّرك حتى تصلي، في المواعيد التي تختارها.

مواقيت الصلاة والقبلة
- مواقيت صلاة دقيقة تُحسب على جهازك بخصوصية تامة، مع طريقة حساب تلقائية مقترحة لمنطقتك، وقائمة كاملة بطرق الحساب تتصفّحها، وزوايا مخصّصة تضبطها بنفسك.
- سماء حيّة فوق مواقيتك: الشمس في مسارها فوق أفق من الأهرامات ومسجد، والنجوم ليلًا، وقمر ثلاثي الأبعاد في طوره الحقيقي. اسحب عبر اليوم لترى السماء في أي لحظة.
- بوصلة القبلة، وأصوات الأذان، وإشعارات الصلاة مع الإشعارات المسبقة، ولوحة «نظرة سريعة» فيها المسافة إلى مكة وساعات النهار والقمر ووقت صيامك.
- أوقات اختيارية للضحى ومنتصف الليل الشرعي والثلث الأخير، ومواقيت الصلاة لأي مدينة أخرى.
- تقويم الصلاة لثلاثة عشر شهرًا قادمة، تصدّره بصيغة PDF أو CSV.
- أدوات لمواقيت الصلاة والعدّ التنازلي، منها أدوات بألوان السماء وأدوات لشاشة القفل، مع تطبيق كامل على Apple Watch.

ميزات فريدة
- «وضع السفر»: اقصر الصلوات واجمعها في سفرك، تلقائيًا أو يدويًا، مع مزامنة بين iPhone وApple Watch.
- البحث بالذكاء الاصطناعي على جهازك: ابحث في الأدعية والأذكار وأسماء الله الحسنى بالمعنى لا بالكلمة وحدها. يعمل البحث بالمعنى بالعبارات الإنجليزية حاليًا.
- مع Apple Intelligence، يجيبك «اسأل الذكاء الاصطناعي» من المصادر التي يعرضها لك ويستشهد بها، ولا يُصدر فتوى أبدًا.
- «أسماء مخصّصة للصلوات»: اكتب اسم كل صلاة كما تنطقه، فيظهر كذلك في كل مكان من التطبيق.
- اختصارات Siri: اسأل عن موعد المغرب، أو الصلاة الحالية، أو الصلاة القادمة، بالعربية أو بالإنجليزية.

رمضان
- نشاط مباشر يعدّ الوقت تنازليًا إلى السحور قبل الفجر، وإلى الإفطار قبل المغرب.
- التاريخ الهجري والتقويم الإسلامي بمناسباته مثل رمضان والعيد، مع إشعارات بالمناسبات.
- تعديل التاريخ الهجري، مع خيار لتقديم التاريخ عند المغرب.

التذكير اليومي والتعلّم
- «اليوم»: دعاء اليوم واسم من أسماء الله الحسنى وتذكرة اليوم، مع دفتر يوميات وعدّاد للتسبيح.
- أذكار موثّقة وحصن المسلم ومجموعات أدعية، مع زر «استماع» يقرأ النص العربي بصوت مسموع.
- أسماء الله الحسنى بالتفصيل، ودليلا المساجد والطعام الحلال، ومحوّل التاريخ الهجري، وخلفيات إسلامية.
- أدلة عملية للصلاة والصيام والزكاة والحج والعمرة والوضوء والغسل وصلاتي الجمعة والعيد.
- تعلّم الحروف العربية مع «اختبار القراءة» في ٢١ مستوًى، وأحكام التلاوة في «أساسيات التجويد».
- اقرأ «إثبات الإسلام» و«معجزات القرآن» وأركان الإسلام والإيمان.

على طريقتك
- الواجهة بالعربية والإنجليزية، حسب اللغة التي تختارها للتطبيق في إعدادات iOS. أما المقالات المفصّلة في تبويب الإسلام فبالإنجليزية حاليًا.
- «الوضع المبسّط» يُبقي الأساسيات على الشاشة، وبإمكانك التبديل إلى الوضع الكامل متى شئت.
- أحجام النص، والخطوط العربية، وألوان التمييز والسماء، وغيرها، مع شريط بحث في كل صفحة إعدادات.

مجاني، بلا إعلانات، ويحفظ خصوصيتك
تطبيق الأذان مجاني تمامًا. لا إعلانات، ولا حسابات، ولا اشتراكات، ولا تتبّع: لا يُجمَع شيء مما تفعله ولا يُشارَك.

سواء كنت تبحث عن مواقيت الصلاة أو اتجاه القبلة أو فهمٍ أعمق للإسلام، حمّل تطبيق الأذان اليوم وتابع رحلتك الإيمانية.
```

**3,300 / 4,000 characters.**

## 6. What's New

Version 2.6.6, the release that adds the Arabic interface. The Arabic interface and the choice of
language come first, unchanged; the language section gains one line saying the app speaks Urdu too
(the English "Languages" line). Below them are the English notes at the top of `Whats New.md`
(Version 2.6.6), translated under the same headings, with Islamic Tools as تبويب الإسلام. Version 2.6.5 went live on 2026-10-15 with English notes only, so nothing from it is repeated here.

Translation notes:
- **The clocks change** is the daylight-saving change (تغيير التوقيت).
- **Sunnahs of the Prophet:** the catalog's label ends in the one-glyph honorific; the store spells it out.

```
تطبيق الأذان كله الآن بالعربية، بواجهة من اليمين إلى اليسار في المواقيت والقبلة وتبويب الإسلام والإعدادات.

الواجهة العربية:
- الشاشات والقوائم والإعدادات والإشعارات والأدوات كلها بالعربية، على iPhone وiPad وMac وApple Watch.
- تخطيط من اليمين إلى اليسار في كل مكان، وتبقى النصوص الإنجليزية، كمعاني الأدعية بالإنجليزية، من اليسار إلى اليمين لتُقرأ بسهولة.
- يظهر اسم التطبيق بالعربية على الشاشة الرئيسية: «الأذان».
- تحدّث إلى Siri بالعربية: اسأل عن موعد أي صلاة، أو عن الصلاة الحالية، أو الصلاة القادمة.
- تصلك إشعارات الصلاة بالعربية، ويظهر اسم مدينتك بلغة الواجهة.
- تتبع الأرقام منطقة جهازك، فتظهر هكذا ١٢٣ أو هكذا 123 حسب إعدادات المنطقة في iOS.

اختيار اللغة:
- يتبع التطبيق اللغة التي تختارها له في إعدادات iOS، ويوصلك إليها صف «اللغة» في إعدادات التطبيق.
- التطبيق متاح بالأردية أيضًا.
- عند تغيير اللغة تُعاد جدولة إشعاراتك باللغة الجديدة.
- تبقى المقالات المفصّلة في تبويب الإسلام بالإنجليزية حاليًا.

مواقيت الصلاة:
- التاريخ الهجري لليوم، أو لهذا الأسبوع، تحت العد التنازلي، مع تنبيه قبل يوم من تغيير التوقيت.
- خمسة تخطيطات لمواقيت الصلاة، منها مربعات زجاجية ومربعات في منتصف الشاشة.

الإشعارات:
- أزرار «هل صلّيت؟» في كل إشعار صلاة.
- «السماح بالإشعارات»: مفتاح واحد لكل ما يرسله التطبيق.
- إعدادات الإشعارات وإشعارات الصلاة و«وضع التذكير المتكرر» بتصميم جديد، مع صفحة لكل صلاة.
- يلتزم الأذان داخل التطبيق بالوضع الصامت، ويعرض عليك زر «تشغيل» بدلًا من ذلك.

تبويب الإسلام:
- «سنن النبي صلى الله عليه وسلم»: ١٢٩ سنة يومية مع مصادرها.
- «الأبجدية العربية»: همزة الوصل، وحروف العلة، والألف المقصورة والياء، وقسم «الإعراب»، ولكل منها تدريبات.
- صفحة كل رواية تذكر الآن ما يميزها.
- أدلة جديدة للخطبة والرقية، ودليل أوفى لصلاة الجمعة.
- طي أقسام أي تبويب أو إخفاؤها، وأشرطة مرقمة في القوائم الطويلة، وشريط بحث في كل مصدر.

الإعدادات:
- صفحات الإعدادات كلها بأسلوب واحد، مع شرح تحت كل خيار.
- «إعدادات الإسلام»: صفحة خاصة بتبويب الإسلام.
- تنبيه «يتوفر تحديث» عند صدور إصدار أحدث في App Store.

إصلاحات وتحسينات:
- شاشات إعدادات أسرع، وقوائم بلا تأخير، وإصلاحات على iPhone وiPad وMac وApple Watch.
```

**2,006 / 4,000 characters.**

## Glossary

The Arabic the app shows for the features the listing names (Al-Islam's `Resources/Localizable.xcstrings`,
synced to Al-Adhan). The three marked * have no label of their own in the catalog: they are the words Apple's
Arabic pages use.

| English | Arabic |
|---|---|
| Al-Adhan (the app and its tab), the Islam tab, Settings | الأذان (تطبيق الأذان in a sentence)، تبويب الإسلام، الإعدادات |
| Prayer Times | مواقيت الصلاة |
| Simple Mode / Full | الوضع المبسّط / كامل |
| Prayer Tracker | متتبّع الصلاة |
| Streak, Perfect Days | سلسلة الأيام، الأيام المثالية |
| "Did you pray?" | هل صلّيت؟ |
| Traveling Mode | وضع السفر |
| Nagging Mode | وضع التذكير المتكرر |
| Pre-notifications | الإشعارات المسبقة |
| Automatic (method), Custom Angles | تلقائي، زوايا مخصّصة |
| At a Glance, Distance to Makkah | نظرة سريعة، المسافة إلى مكة |
| Sky Fills the Screen, Sky Colors | السماء تملأ الشاشة، ألوان السماء |
| Duhaa, Islamic Midnight, Last Third | الضحى، منتصف الليل الشرعي، الثلث الأخير |
| Prayer Calendar, City Prayer Times | تقويم الصلاة، مواقيت صلاة المدن |
| Custom Prayer Names | أسماء مخصّصة للصلوات |
| Hijri Calendar, Hijri Offset, Hijri Converter | التقويم الهجري، تعديل التاريخ الهجري، محوّل التاريخ الهجري |
| Suhoor, Iftar | السحور، الإفطار |
| Ask AI, Search by meaning | اسأل الذكاء الاصطناعي، البحث بالمعنى |
| Today, Reminder of the Day | اليوم، تذكرة اليوم |
| Journal, Tasbih | اليوميات، التسبيح |
| Hisn al-Muslim, Listen | حصن المسلم، استماع |
| 99 Names of Allah | أسماء الله الحسنى |
| Masjid and Halal Food Locators | دليل المساجد، دليل الطعام الحلال |
| Islamic Wallpapers | خلفيات إسلامية |
| How-To Guides | الأدلة العملية |
| Reading Test, Tajweed Foundations | اختبار القراءة، أساسيات التجويد |
| Proving Islam, Miracles of the Quran | إثبات الإسلام، معجزات القرآن |
| Miracles of the Prophets, Prophecies of the Prophet | معجزات الأنبياء، نبوءات النبي صلى الله عليه وسلم |
| Tips & Tricks, Language (Settings row) | نصائح وحيل، اللغة |
| Accent Color, Lock Screen | لون التمييز، شاشة القفل |
| widgets*, complication*, Live Activity* | الأدوات، المضاعفة، النشاط المباشر |
| Allow Notifications, Prayer Notifications, Play (button), Silent Mode | السماح بالإشعارات، إشعارات الصلاة، تشغيل، الوضع الصامت |
| Hijri Date, Islam Settings, Update Available | التاريخ الهجري، إعدادات الإسلام، يتوفر تحديث |
| Sunnahs of the Prophet (the honorific spelled out) | سنن النبي صلى الله عليه وسلم |
| Arabic Alphabet, Hamzat al-Wasl, Vowel Letters, Grammar | الأبجدية العربية، همزة الوصل، حروف العلة، الإعراب |
