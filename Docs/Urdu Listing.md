# App Store Urdu Listing

The **Urdu** localization of the App Store listing for **Al-Adhan | Prayer Times**. In App Store Connect
(Urdu listings since 2026-03-31), add the Urdu localization, then fill Name and Subtitle under App Information
and the other four fields on the version page. Screenshots can stay English: App Store Connect shows the
primary language's screenshots for a localization that has none of its own.
People whose device is set to Urdu see this listing instead of the English one. In the Urdu interface the app
calls itself الاذان, and the catalog names its tabs اذان، اسلام and ترتیبات; the listing uses the same words.
Modeled on this folder's `Arabic Listing.md` (its structure and its claims) and on Al-Islam's
`Docs/App Store/Urdu Listing.md` (its Urdu style and guidelines).

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
  `python3 -c 'import re;f=chr(96)*3;t=open("Docs/Urdu Listing.md").read();[print(len(b)) for b in re.findall(f+"\n(.*?)\n"+f,t,re.S)]'`
- **Standard Urdu as Apple's own Urdu pages read it**, with the respectful register (نبی کریم ﷺ).
  Feature names are the labels the app shows (Al-Islam's `Resources/Localizable.xcstrings`, which Al-Adhan
  receives in its sync; see the glossary below).
- **Inside a sentence the app is الاذان ایپ**, name first, with feminine verbs (ایپ ... کرتی ہے). A bare اذان
  in running text is the call to prayer itself; the tab is اذان ٹیب.
- **No em dash, and no spaced hyphen used as a dash.** Use a colon, the comma ، or a new sentence. A leading
  "- " bullet is fine; the English fields use the same.
- **Urdu punctuation** (۔ ، ؟) and Western digits (13، 21), as Urdu in Pakistan writes them. No version numbers.
- **Urdu letters, never their Arabic look-alikes:** ی ک ہ ھ ۃ, not ي ك ه ة.
- **Brand names stay Latin:** Apple, Siri, Apple Watch, Apple Intelligence, iPhone, iPad, Mac, iOS; so do
  PDF, CSV and OC Ummah.
- **No zabar, zer or shadda in the name, subtitle or keywords:** nobody types them in a search. The
  description and notes may use them where the app's own label does (اثباتِ اسلام، حسبِ منشا زاویے).
- **Only what the English listing claims.** Every feature named here is in `Arabic Listing.md`, which is
  held to Al-Adhan's English `App Store Description.md` and `Whats New.md`. Al-Adhan has no Quran reader and
  no Hadith tab: no Quran or hadith features and no Quran or hadith search terms (the English `Keywords.md`
  excludes them too).
- **Be honest about what is still English:** the in-depth articles of the Islam tab (Proving Islam, the
  How-To Guides, the pillars and the miracles libraries among them), AI search by meaning, which matches
  English phrases only, and Siri, which has no Urdu. Where the Arabic listing says to ask Siri in Arabic,
  this one says to ask in English or Arabic.
- **No scripture quoted.** No Quranic text and no hadith presented as the Prophet's words.
- Keep in sync with the English docs (`App Store Description.md`, `Keywords.md`, `Promotional Text.md`,
  `Whats New.md`) and with `Arabic Listing.md`: when a field changes for a feature, change it here too.

## 1. Name

Names are unique across the store, so a bare الاذان will not be accepted. Each option keeps الاذان first,
then a short descriptor after a separator, as the English name does with "|".

**Recommended:**

```
الاذان | نماز کے اوقات، قبلہ
```

**28 / 30 characters.**

The English name, plus the Qibla. "نماز کے اوقات" is how Urdu says prayer times and the most searched prayer
phrase; it stays whole, کے included, in case Apple's Urdu search does not drop it. There is room left for
قبلہ, the second thing people come for, so the subtitle can carry the Hijri calendar and Ramadan.

**Alternate A:**

```
الاذان | نماز کے اوقات
```

**22 / 30 characters.**

The English name word for word. Pair it with a subtitle that takes the Qibla, for example
سمت قبلہ، ہجری کیلنڈر، رمضان (28 characters), and in the keyword field replace سمت and رمضان (now in the
subtitle) with سحری and افطار (100 characters, the limit).

**Alternate B:**

```
الاذان | اوقات نماز، قبلہ
```

**25 / 30 characters.**

The other common phrasing (اوقاتِ نماز, written without its zer): the same words without کے. The subtitle and
keywords below stay as they are. Prefer it only if App Analytics shows "اوقات نماز" outsearching "نماز کے
اوقات".

## 2. Subtitle

**Recommended** (with the recommended name):

```
ہجری کیلنڈر، سحری و افطار
```

**25 / 30 characters.**

Two phrases people type whole: ہجری کیلنڈر for the Hijri calendar, its events and Eid; سحری و افطار for the
Ramadan Live Activity, which counts down to both. With the name's اوقات it also answers "سحری و افطار کے
اوقات", a phrase Urdu searches use every Ramadan. In Urdu و is a word of its own, so nothing is attached to
سحری or افطار.

**Alternate:**

```
نماز ٹریکر، ہجری کیلنڈر، اذکار
```

**30 / 30 characters.**

Leads with the prayer tracker, as the English description does. It repeats the name's نماز (5 characters) to
keep the app's label نماز ٹریکر whole. With it, the keyword field replaces ٹریکر and اذکار (now in the
subtitle) with سحری and افطار (98 characters).

## 3. Keywords

Written for the recommended name and subtitle. No word repeats one of theirs (الاذان، نماز، کے، اوقات، قبلہ،
ہجری، کیلنڈر، سحری، و، افطار); as in the Arabic field, a word without ال (اذان) or in another form (وقت beside
اوقات, سحر beside سحری) is a search term of its own. If an alternate ships, re-check that and swap in the
words it dropped.

```
اذان,وقت,فجر,الارم,ٹریکر,سمت,نما,کمپاس,مکہ,اسلامی,چاند,رمضان,سحر,روزہ,عید,اذکار,دعا,تسبیح,مسجد,حلال
```

**99 / 100 characters.**

Why these terms:
- **اذان، وقت، فجر، الارم:** اذان as Urdu writes it, without the name's ال ("فجر کی اذان"); وقت, the singular,
  for "نماز کا وقت" and "مغرب کا وقت" (the name has the plural اوقات); فجر and الارم for "فجر الارم" and
  "نماز الارم", the alarm searches that adhan notifications answer.
- **ٹریکر:** with the name's نماز, the app's own label نماز ٹریکر.
- **سمت، نما، کمپاس، مکہ:** with the name's قبلہ, "سمت قبلہ" for the direction, "قبلہ نما" and "قبلہ کمپاس"
  for the compass (Urdu calls it both ways), and "مکہ کی سمت" (the At a Glance board shows the distance to
  Makkah).
- **اسلامی، چاند:** with the subtitle's کیلنڈر, "اسلامی کیلنڈر"; "چاند کی تاریخ", the everyday Urdu for the
  Hijri date, which also finds the 3D moon.
- **رمضان، سحر، روزہ، عید:** the Ramadan Live Activity; سحر for "سحر و افطار", the other common phrasing
  beside the subtitle's سحری; fasting (the At a Glance board's fasting window); the Islamic calendar's Eid
  dates and their notifications.
- **اذکار، دعا، تسبیح:** the adhkar and dua collections (Hisn al-Muslim among them) and the tasbih counter.
- **مسجد، حلال:** the Masjid and Halal Food locators.

Left out for room, to rotate in from App Analytics: افطاری، حصن، المسلم، جمعہ، قصر (for "نماز قصر",
Traveling Mode)، تاریخ، مسلمان، وال پیپر. Deliberately excluded, as in the English `Keywords.md`: قرآن، تفسیر،
حدیث، قاری، سورت، پارہ, and تجوید (the Islam tab has Tajweed Foundations, but no Quran reader, so most people
who search it would be disappointed); those searches belong to Al-Islam and Al-Quran. If Apple's Urdu search
turns out to match اذان inside الاذان, or سحر inside سحری, those two are redundant and are the first to swap.

## 4. Promotional Text

Leads with the Urdu interface. Update it with the next release like the English one. Siri has no Urdu, so
where the Arabic text offers Siri in Arabic, this one offers the prayer notifications in Urdu.

```
نیا: مکمل اردو انٹرفیس، دائیں سے بائیں، اور نماز کی اطلاعات بھی اردو میں۔ نماز کے اوقات، قبلہ اور نماز ٹریکر ایک مفت ایپ میں، بغیر اشتہارات کے۔
```

**143 / 170 characters.**

## 5. Description

An Urdu rendering of the Arabic listing's Description (itself `App Store Description.md`, section for
section), with the English ALL-CAPS headers as short Urdu headings on their own lines. It keeps the Arabic
text's three differences from the English (sky widgets for the "Prayer Sky widget", Tajweed Foundations in the
learning line, and a line on the interface opening آپ کے انداز میں), and adds two of its own: that line names
Urdu, Arabic and English, and the Siri line says to ask in English or Arabic, since Siri has no Urdu.

```
الاذان ایپ ہر روز کی نماز میں آپ کی ساتھی ہے، چاہے آپ پیدائشی مسلمان ہوں، حال ہی میں اسلام قبول کیا ہو، یا اسلام کو جاننے آئے ہوں۔ نماز کے اوقات، نماز ٹریکر، قبلہ، ہجری کیلنڈر اور آپ کی ڈیوائس پر اے آئی سے تلاش، سب ایک سادہ ایپ میں: مکمل طور پر مفت، بغیر اشتہارات کے، اور آپ کی رازداری کے ساتھ۔

نماز ٹریکر
- ہر نماز ایک ٹیپ سے درج کریں، مسلسل دنوں، مثالی دنوں اور ایک رنگین کیلنڈر کے ساتھ جو دن، ہفتے، مہینے اور سال کے لحاظ سے آپ کی پابندی دکھاتا ہے۔
- جمعہ اور سفر میں جمع کی گئی نمازیں درست طور پر شمار ہوتی ہیں، اور حیض اور نفاس کے دن مسلسل دنوں کا سلسلہ کبھی نہیں توڑتے۔
- نماز کی کسی بھی اطلاع پر ٹیپ کر کے «کیا آپ نے نماز پڑھ لی؟» کا جواب دیں، اور «بار بار یاد دہانی کا موڈ» آپ کے چنے ہوئے اوقات میں نماز ادا کرنے تک یاد دلاتا رہے۔

نماز کے اوقات اور قبلہ
- درست نماز کے اوقات، جن کا حساب مکمل رازداری سے آپ کی ڈیوائس پر ہوتا ہے، اور ساتھ میں آپ کے علاقے کے لیے تجویز کردہ خودکار طریقہ، حساب کے تمام طریقوں کی فہرست، اور «حسبِ منشا زاویے» جو آپ خود مقرر کریں۔
- آپ کے اوقات کے اوپر ایک جیتا جاگتا آسمان: اہرام اور ایک مسجد والے افق کے اوپر اپنی راہ چلتا سورج، رات کو ستارے، اور اصل منزل میں سہ جہتی چاند۔ دن بھر میں انگلی پھیر کر کسی بھی لمحے کا آسمان دیکھیں۔
- قبلہ کا قطب نما، اذان کی آوازیں، نماز کی اطلاعات اور پیشگی اطلاعات، اور «ایک نظر میں» کا حصہ، جو مکہ مکرمہ تک فاصلہ، دن کی روشنی، چاند اور آپ کے روزے کا دورانیہ دکھاتا ہے۔
- چاشت، شرعی آدھی رات اور آخری تہائی کے اختیاری اوقات، اور کسی بھی دوسرے شہر کے نماز کے اوقات۔
- اگلے 13 مہینوں کا نماز کا کیلنڈر، جسے آپ PDF یا CSV میں برآمد کر سکتے ہیں۔
- نماز کے اوقات اور الٹی گنتی کے ویجیٹس، جن میں آسمان والے ویجیٹس اور لاک اسکرین کے ویجیٹس بھی شامل ہیں، اور Apple Watch کی مکمل ایپ۔

منفرد خصوصیات
- سفر موڈ: سفر میں نمازیں قصر اور جمع کریں، خودکار یا دستی طور پر، iPhone اور Apple Watch کے درمیان ہم آہنگی کے ساتھ۔
- آپ کی ڈیوائس پر اے آئی سے تلاش: دعاؤں، اذکار اور اللہ کے ننانوے ناموں میں صرف الفاظ کے بجائے معنی کے لحاظ سے تلاش کریں۔ معنی سے تلاش فی الحال انگریزی جملوں سے ہوتی ہے۔
- Apple Intelligence کے ساتھ، «اے آئی سے پوچھیں» انہی ذرائع سے جواب دیتا ہے جو وہ آپ کو دکھاتا ہے اور جن کا حوالہ دیتا ہے، اور کبھی فتویٰ نہیں دیتا۔
- «نمازوں کے حسبِ منشا نام»: ہر نماز کا نام ویسے لکھیں جیسے آپ بولتے ہیں، اور وہ پوری ایپ میں اسی طرح نظر آئے گا۔
- Siri اور شارٹ کٹس: مغرب کا وقت، موجودہ نماز یا اگلی نماز انگریزی یا عربی میں پوچھیں، کیونکہ Siri اردو نہیں بولتا۔

رمضان
- لائیو ایکٹیویٹی جو فجر سے پہلے سحری کی، اور مغرب سے پہلے افطار کی الٹی گنتی کرتی ہے۔
- ہجری تاریخ اور اسلامی کیلنڈر، رمضان اور عید جیسے مواقع کے ساتھ، اور ان مواقع کی اطلاعات۔
- ہجری تاریخ میں کمی بیشی، اور مغرب پر ہجری تاریخ بدلنے کا اختیار۔

روزانہ کی یاد دہانی اور سیکھنا
- «آج»: آج کی دعا، اللہ کا ایک نام اور آج کی یاد دہانی، ڈائری اور تسبیح کاؤنٹر کے ساتھ۔
- مستند اذکار، حصن المسلم اور دعاؤں کے مجموعے، «سنیں» کے بٹن کے ساتھ جو عربی متن بلند آواز میں پڑھ کر سناتا ہے۔
- اللہ کے ننانوے نام تفصیل سے، مسجد اور حلال کھانے کی تلاش، ہجری تاریخ کی تبدیلی، اور اسلامی وال پیپرز۔
- نماز، روزہ، زکوٰۃ، حج، عمرہ، وضو، غسل، اور جمعہ اور عید کی نمازوں کے لیے «عملی رہنمائی»۔
- 21 درجوں کے ریڈنگ ٹیسٹ کے ساتھ عربی حروف سیکھیں، اور «تجوید کی بنیادیں» میں تلاوت کے احکام۔
- «اثباتِ اسلام»، «قرآن کے معجزات»، اور اسلام اور ایمان کے ارکان پڑھیں۔

آپ کے انداز میں
- انٹرفیس اردو، عربی اور انگریزی میں، اس زبان کے مطابق جو آپ iOS کی سیٹنگز میں ایپ کے لیے منتخب کریں۔ اسلام ٹیب کے تفصیلی مضامین فی الحال انگریزی میں ہیں۔
- سادہ موڈ صرف بنیادی چیزیں سامنے رکھتا ہے، اور آپ جب چاہیں مکمل موڈ پر جا سکتے ہیں۔
- متن کے سائز، عربی فونٹس، نمایاں رنگ اور آسمان کے رنگ، اور بہت کچھ، ترتیبات کے ہر صفحے پر تلاش کے ساتھ۔

مفت، بغیر اشتہارات، آپ کی رازداری محفوظ
الاذان ایپ مکمل طور پر مفت ہے۔ نہ اشتہارات، نہ اکاؤنٹس، نہ سبسکرپشن، نہ ٹریکنگ: آپ کی کوئی سرگرمی جمع یا شیئر نہیں کی جاتی۔

چاہے آپ نماز کے اوقات ڈھونڈ رہے ہوں، قبلہ کی سمت، یا اسلام کی گہری سمجھ، آج ہی الاذان ایپ ڈاؤن لوڈ کریں اور اپنا ایمانی سفر جاری رکھیں۔
```

**3,837 / 4,000 characters.**

## 6. What's New

The release that adds the Urdu interface. The Urdu interface comes first: Al-Islam's Urdu "اردو انٹرفیس" and
"زبان کا انتخاب", without its surah, hadith-book and tajweed-course lines (not Al-Adhan features), plus the
Arabic text's home-screen name line (the sync derives the Urdu display name, الاذان, from the catalog's
"Al-Adhan"). The Arabic text's clause on the city name in the interface language is left out: it is not
checked for Urdu. Below it is the rest of the Arabic listing's What's New (the English notes at the top of
`Whats New.md`, Version 2.6.5), translated under the same headings, with its same two changes:
- **Wallpapers:** the English says "Two new wallpapers", the second a Free Palestine poster with the Dome of
  the Rock. That poster is not new (the photo wallpaper has shipped since 2025), so only OC Ummah's desert
  night is listed.
- **Tips & Tricks:** the English "150 Tips & Tricks" is not true of Al-Adhan, which shows fewer of them (the
  catalogue is filtered per app). No count is given.

```
الاذان ایپ اب مکمل طور پر اردو میں ہے، نماز کے اوقات، قبلہ، اسلام ٹیب اور ترتیبات میں دائیں سے بائیں انٹرفیس کے ساتھ۔

اردو انٹرفیس:
- تمام اسکرینیں، مینیو، ترتیبات، اطلاعات اور ویجیٹس اردو میں، iPhone، iPad، Mac اور Apple Watch پر۔
- ہر جگہ دائیں سے بائیں ترتیب، جبکہ انگریزی متن، جیسے دعاؤں کے انگریزی ترجمے، آسانی سے پڑھنے کے لیے بائیں سے دائیں رہتا ہے۔
- ہوم اسکرین پر ایپ کا نام اردو میں: «الاذان»۔
- نماز کی اطلاعات اردو میں آتی ہیں۔
- ہندسے iOS کی ترتیبات کے مطابق: عام طور پر 0-9، اور اگر آپ نے اردو ہندسے چنے ہیں تو ۰-۹۔

زبان کا انتخاب:
- ایپ اس زبان کی پیروی کرتی ہے جو آپ iOS کی سیٹنگز میں اس کے لیے منتخب کریں، اور ایپ کی ترتیبات میں «زبان» کی قطار آپ کو وہاں لے جاتی ہے۔
- زبان بدلنے پر آپ کی اطلاعات نئی زبان میں دوبارہ ترتیب پاتی ہیں۔
- Siri اردو نہیں بولتا، اس لیے Siri سے انگریزی یا عربی میں نماز کے اوقات پوچھیں۔
- اسلام ٹیب کے تفصیلی مضامین فی الحال انگریزی میں ہیں۔

آسمان:
- چاند پر ٹیپ کر کے اصل منزل میں سہ جہتی چاند دیکھیں، اور اسے جیسے چاہیں گھمائیں۔
- افق پر اہرام اور ایک مسجد، جنہیں دن میں سورج اور رات کو چاند روشن کرتا ہے۔
- «آسمان پوری اسکرین پر» کا اختیار پورے اذان ٹیب کو آسمان کے رنگوں سے بھر دیتا ہے۔
- آسمان والے ویجیٹس اور Apple Watch کی کمپلیکیشن رات کا آسمان ستاروں کے ساتھ دکھاتے ہیں، اور سفر میں عشاء کے اصل وقت پر رات میں بدل جاتے ہیں۔

نماز کے اوقات اور قبلہ:
- حساب کے کئی طریقوں میں زیادہ درست اوقات، برونائی کے لیے نیا طریقہ، اور خطِ استوا سے دور علاقوں میں بہتر حساب۔
- سفر موڈ کی پٹی بتاتی ہے کہ نمازیں کیوں جمع ہو رہی ہیں اور آپ گھر سے کتنے دور ہیں۔
- قبلہ کی سوئی ہر سائز میں ہموار گھومتی ہے، سمت ابھی طے نہ ہوئی ہو تو بتا دیتی ہے، اور کیلیبریشن کی پیشکش کرتی ہے۔

اطلاعات اور نماز ٹریکر:
- نماز کی اطلاع پر ٹیپ کرنے سے «کیا آپ نے نماز پڑھ لی؟» پوچھا جاتا ہے، اور آپ ایک ٹیپ سے نماز درج کر لیتے ہیں۔
- «بار بار یاد دہانی کا موڈ» اب اپنے الگ صفحے پر: یاد دہانیوں کا درمیانی وقفہ، آخری یاد دہانی اور شروع ہونے کا وقت خود چنیں۔
- اگر آپ چند منٹ دیر سے ایپ کھولیں تو وہ ایک بار اذان چلانے کی پیشکش کرتی ہے۔
- اذان چلتے وقت آپ اسے ایپ میں کہیں سے بھی روک سکتے ہیں۔

اسلام ٹیب:
- «آج»: آج کی دعا، اللہ کا ایک نام اور آج کی یاد دہانی ایک ہی اسکرین پر۔
- ریڈنگ ٹیسٹ کے 21 درجے، الگ الگ حروف سے لے کر بغیر اعراب کے متن تک۔
- انگریزی میں نئے کتب خانے: «اثباتِ اسلام»، «انبیاء کے معجزات» اور «نبی کریم ﷺ کی پیش گوئیاں»۔
- «اے آئی سے پوچھیں» اپنے ذرائع نمبر والے کارڈز میں بتاتا ہے، جنہیں آپ ایک ٹیپ سے کھول سکتے ہیں۔
- نیا وال پیپر: OC Ummah کی صحرائی رات۔

ترتیبات:
- سادہ موڈ صرف بنیادی چیزیں سامنے رکھتا ہے، اور آپ جب چاہیں مکمل موڈ پر جا سکتے ہیں۔
- ترتیبات کے ہر صفحے پر تلاش کی پٹی، اور «تجاویز اور ترکیبیں» کا حصہ۔

اصلاحات اور بہتریاں:
- Apple Watch پر تیز آغاز، اور iPhone، iPad، Mac اور Apple Watch پر درجنوں کریش کی اصلاحات۔
```

**2,675 / 4,000 characters.**

## Glossary

The Urdu the app shows for the features the listing names (Al-Islam's `Resources/Localizable.xcstrings`,
synced to Al-Adhan). "Did you pray?" has no label of its own: it is the question as the catalog's Nagging Mode
strings ask it. The two marked * have no Urdu label in the catalog: لائیو ایکٹیویٹی is the word Al-Islam's
Urdu listing uses, and کمپلیکیشن is the English loanword; check both against Apple's Urdu pages before
submitting.

| English | Urdu |
|---|---|
| Al-Adhan (the app), the Adhan tab, the Islam tab, Settings | الاذان (الاذان ایپ in a sentence)، اذان ٹیب، اسلام ٹیب، ترتیبات |
| Prayer Times | نماز کے اوقات |
| Simple Mode / Full | سادہ موڈ / مکمل |
| Prayer Tracker | نماز ٹریکر |
| Streak, Perfect Days | مسلسل دن، مثالی دن |
| "Did you pray?" | کیا آپ نے نماز پڑھ لی؟ |
| Traveling Mode | سفر موڈ |
| Nagging Mode | بار بار یاد دہانی کا موڈ |
| Prayer Notifications, Pre-notifications | نماز کی اطلاعات، پیشگی اطلاعات |
| Qibla Compass, Adhan sounds, Stop adhan | قبلہ کا قطب نما، اذان کی آوازیں، اذان روکیں |
| Automatic (method), Custom Angles | خودکار، حسبِ منشا زاویے |
| At a Glance, Distance to Makkah | ایک نظر میں، مکہ مکرمہ تک فاصلہ |
| Daylight, Moon, Fasting Window | دن کی روشنی، چاند، روزے کا دورانیہ |
| Sky Fills the Screen, Sky Colors | آسمان پوری اسکرین پر، آسمان کے رنگ |
| Duhaa, Islamic Midnight, Last Third | چاشت، شرعی آدھی رات، آخری تہائی |
| Prayer Calendar, City Prayer Times | نماز کا کیلنڈر، شہروں کے نماز کے اوقات |
| Custom Prayer Names | نمازوں کے حسبِ منشا نام |
| Hijri Calendar, Hijri Offset, Hijri Converter | ہجری کیلنڈر، ہجری تاریخ میں کمی بیشی، ہجری تاریخ کی تبدیلی |
| Switch Hijri Date at Maghrib, Islamic Calendar Notifications | مغرب پر ہجری تاریخ بدلیں، اسلامی کیلنڈر کی اطلاعات |
| Suhoor, Iftar, Ramadan, Eid | سحری، افطار، رمضان، عید |
| Ask AI, Search by meaning | اے آئی سے پوچھیں، معنی کے لحاظ سے تلاش کریں |
| Siri and Shortcuts | Siri اور شارٹ کٹس |
| Today, Dua of the Day, Name of Allah, Reminder of the Day | آج، آج کی دعا، اللہ کا نام، آج کی یاد دہانی |
| Journal, Tasbih Counter | ڈائری، تسبیح کاؤنٹر |
| Hisn al-Muslim, Listen | حصن المسلم، سنیں |
| 99 Names of Allah | اللہ کے ننانوے نام |
| Masjid Locator, Halal Food Locator | مسجد کی تلاش، حلال کھانے کی تلاش |
| Islamic Wallpapers, Wallpapers | اسلامی وال پیپرز، وال پیپرز |
| How-To Guides | عملی رہنمائی |
| Reading Test, Tajweed Foundations | ریڈنگ ٹیسٹ، تجوید کی بنیادیں |
| Proving Islam, Miracles of the Quran | اثباتِ اسلام، قرآن کے معجزات |
| Miracles of the Prophets, Prophecies of the Prophet | انبیاء کے معجزات، نبی کریم ﷺ کی پیش گوئیاں |
| Tips & Tricks, Language (Settings row) | تجاویز اور ترکیبیں، زبان |
| Accent Color, Lock Screen | نمایاں رنگ، لاک اسکرین |
| Widgets, Widgets with a sky, Prayer Countdown | ویجیٹس، آسمان والے ویجیٹس، نماز کی الٹی گنتی |
| complication*, Live Activity* | کمپلیکیشن، لائیو ایکٹیویٹی |
