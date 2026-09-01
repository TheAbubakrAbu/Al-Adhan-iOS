import SwiftUI
import Foundation

// Ask AI - a conversation with Apple's on-device model about prayer and Islam, the way one would
// ask any assistant: type a question, read the answer, follow up. Private, offline, free
// (iOS 26 + Apple Intelligence; `OnDeviceAsk.isAvailable`).
//
// Independent of the search screens ON PURPOSE. The chat runs the app's retrieval lanes ITSELF for
// every question - today's computed prayer times, and the Islam tab's article corpus - and hands
// the best passages to the model as SUPPORT, not as a fence: the model answers from what it knows
// and cites the passages it actually used, and each cited article is a real row beneath the reply
// that opens it. Nothing here reads a search field or a results list, so the answer never depends
// on what happened to be typed or retrieved elsewhere.
//
// Reached from the ASK AI row of the Adhkar, Duas, Names and Arabic searches (which open it with
// the typed query as the first question) and from the Islam tab's "Ask AI" resource.

#if os(iOS)

// MARK: - Passages

/// One passage the assistant may draw on for a turn: today's prayer times, or an article section the
/// retrieval found for the question, with the reference exactly as the app prints it ("How to Pray").
struct AskAIPassage: Identifiable, Equatable {
    enum Kind: Equatable {
        /// A section of an Islam-tab article (Pillars, Beliefs, How-to). The row reopens the article.
        case article(id: String)
        /// Today's prayer schedule as THIS app computed it for THIS location. The row is the answer
        /// itself, not a link: there is no single screen a prayer time belongs to.
        case prayer
    }

    let kind: Kind
    let reference: String
    let text: String
    /// How much of `text` the model is shown (`OnDeviceAsk.Source.maxCharacters`).
    var maxCharacters: Int = OnDeviceAsk.chatPassageCharacterLimit
    /// The verse or surah the question itself NAMED: its row always shows beneath the answer, whether
    /// or not the model wrote the reference out ("ayat al-kursi" never says "2:255").
    var isSubject = false

    var id: String { reference }

    var source: OnDeviceAsk.Source { .init(reference: reference, text: text, maxCharacters: maxCharacters, isSubject: isSubject) }
}

// MARK: - Retrieval

/// The chat's own retrieval. A question about prayer gets today's computed times - what this app
/// knows and the model cannot - and every question searches the Islam tab's article corpus, then the
/// two lanes interleave within the model's passage budget. A lane with nothing to say simply
/// contributes nothing: the model still answers.
@MainActor
enum AskAIRetriever {
    /// Words too common to name a topic on their own: the keyword lane never searches for them alone.
    private static let questionWords: Set<String> = [
        "what", "why", "how", "when", "where", "who", "whom", "which", "does", "do", "did", "is", "are",
        "was", "were", "can", "could", "should", "would", "will", "shall", "have", "has", "had", "there",
        "their", "these", "those", "this", "that", "with", "from", "about", "into", "tell", "explain",
        "please", "mean", "means", "meaning", "say", "says", "said", "some", "many", "much", "islam",
        "islamic", "muslim", "muslims", "quran", "hadith", "hadiths", "allah", "prophet", "verse", "verses",
        "surah", "ayah", "ayat",
    ]

    /// The passages for `question`. `previousQuestion` (the user's last question, if any) is folded
    /// into the SEARCH text when this one is a bare follow-up ("why?", "what about zakat?") - on its
    /// own such a question retrieves noise, and the model is still shown the question as typed.
    static func passages(for question: String, previousQuestion: String? = nil,
                         carried: [AskAIPassage] = [],
                         limit: Int = OnDeviceAsk.chatPassageLimit) async -> [AskAIPassage] {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else { return [] }
        var seen = Set<String>()
        // A bare follow-up searches as "previous question + this one", and keeps the passages the
        // previous answer actually cited in the pool - "why?" is about THOSE passages.
        var referenced: [AskAIPassage] = []
        let bareFollowUp = isBareFollowUp(trimmed)
        let searchText: String = {
            guard let previous = previousQuestion?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !previous.isEmpty, bareFollowUp else { return trimmed }
            return previous + " " + trimmed
        }()
        if bareFollowUp {
            for passage in carried.prefix(3) where seen.insert(passage.reference).inserted {
                referenced.append(passage)
            }
        }
        // Lane 1: the app's OWN prayer schedule. "When is Maghrib", "how long until Asr", "how many
        // sunnah rakahs before Dhuhr" are questions about THIS user's day at THIS location, which no
        // model can know and no verse or hadith answers - so today's computed times go in whenever
        // the question is about prayer at all.
        var prayerTimes: [AskAIPassage] = []
        if let passage = prayerPassage(for: searchText), seen.insert(passage.reference).inserted {
            prayerTimes.append(passage)
        }

        // Lane 2: the Islam tab's own articles (Pillars, Beliefs, How-to). The app has a sourced page
        // on wudhu, the madhahib, the pillars and forty other subjects; without this lane the model
        // answered those questions from memory while the app's own page sat one tab away.
        var articles: [AskAIPassage] = []
        // Off the main actor: the corpus is 800 KB of prose, and scanning it inline showed up as a
        // hitch on the keystroke that sent the question.
        let articleHits = await Task.detached(priority: .userInitiated) {
            IslamArticles.search(searchText, limit: 3)
        }.value
        for hit in articleHits {
            guard seen.insert(hit.article.title).inserted else { continue }
            let text = hit.section.heading.isEmpty
                ? hit.section.text
                : "\(hit.section.heading.capitalized): \(hit.section.text)"
            articles.append(AskAIPassage(kind: .article(id: hit.article.id),
                                         reference: hit.article.title, text: text, maxCharacters: 700))
        }

        // The prayer times first - they answer what no model can know - then the app's own articles,
        // round-robin until the budget is spent so neither lane crowds the other out.
        var lanes = [prayerTimes[...], articles[...]]
        var out: [AskAIPassage] = Array(referenced.prefix(limit))
        while out.count < limit, lanes.contains(where: { !$0.isEmpty }) {
            for index in lanes.indices where out.count < limit {
                if let first = lanes[index].first {
                    out.append(first)
                    lanes[index] = lanes[index].dropFirst()
                }
            }
        }
        return out
    }

    /// Words that make a question one about prayer - the prayer lane's whole gate. Deliberately wide
    /// (a bare "when is maghrib" has one of these and nothing else), and cheap: a false positive costs
    /// one passage the model can ignore, a false negative loses the only answer that exists.
    private static let prayerWords: Set<String> = [
        "prayer", "prayers", "pray", "prayed", "praying", "salah", "salat", "salaah", "namaz",
        "fajr", "sunrise", "shuruq", "dhuhr", "duhr", "zuhr", "asr", "maghrib", "isha", "ishaa",
        "jumuah", "jumaah", "jummah", "friday", "duha", "duhaa", "tahajjud", "witr", "qiyam",
        "midnight", "rakah", "rakat", "rakahs", "rakaat", "sunnah", "adhan", "athan", "iqamah",
        "next", "today", "tonight", "schedule", "timetable", "times", "time",
    ]

    /// Today's schedule as a passage: the times this app computed for this location, with each
    /// prayer's fard count and its sunnah rakahs. Nil when the question is not about prayer, or when
    /// no times have been computed yet (no location permission, first launch).
    private static func prayerPassage(for question: String) -> AskAIPassage? {
        let settings = Settings.shared
        let words = Set(question.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted))
        guard !words.isDisjoint(with: prayerWords) else { return nil }
        guard let today = settings.prayers, !today.fullPrayers.isEmpty else { return nil }

        let clock = DateFormatter()
        clock.timeStyle = .short
        clock.dateStyle = .none

        var lines: [String] = []
        for prayer in today.fullPrayers {
            var line = "\(prayer.displayName) \(clock.string(from: prayer.time))"
            var counts: [String] = []
            if prayer.rakah != "0" { counts.append("\(prayer.rakah) fard") }
            if prayer.sunnahBefore != "0" { counts.append("\(prayer.sunnahBefore) sunnah before") }
            if prayer.sunnahAfter != "0" { counts.append("\(prayer.sunnahAfter) sunnah after") }
            if !counts.isEmpty { line += " (" + counts.joined(separator: ", ") + ")" }
            if let note = prayer.sunnahNote { line += ". " + note }
            lines.append(line)
        }
        let day = today.day.formatted(date: .abbreviated, time: .omitted)
        let place = today.city.isEmpty ? "" : " in \(today.city)"
        // Told the current time too: "how long until Asr" is arithmetic the model can only do if it
        // knows where the day stands.
        let text = "Prayer times\(place) for \(day), computed by this app. It is now "
            + "\(clock.string(from: Date())).\n" + lines.joined(separator: "\n")
        return AskAIPassage(kind: .prayer, reference: "Prayer times today", text: text,
                            maxCharacters: 900, isSubject: true)
    }

    /// A question with fewer than two content words ("why?", "and zakat?", "what about that one")
    /// is a follow-up that only makes sense with the previous question beside it.
    private static func isBareFollowUp(_ question: String) -> Bool {
        let separators = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
        let content = question.components(separatedBy: separators)
            .filter { $0.count >= 4 && !questionWords.contains($0.lowercased()) }
        return content.count < 2
    }

}

// MARK: - Answer text hygiene

/// What the model's text goes through before a reader sees it. The on-device model ignores "no
/// markdown" often enough that asterisks were reaching the screen, and it invents hadith numbers and
/// verse references from memory despite being told to cite only the passages - so the parentheses
/// that carry a reference the app did not give it are removed and counted, and the rows beneath the
/// answer stay exactly the verified ones.
enum AskAIAnswerText {
    private static let preambleRegex = try! NSRegularExpression(
        pattern: #"(?i)\A\s*(?:sure|certainly|of course|absolutely|great question|good question)[^\n]{0,60}[!:.]\s*\n+"#)

    /// The transcript's label grammar, echoed back: a reply that opens with "Q: ...\n\nA:" is cut to
    /// what follows the A: (nothing, while the echo is still streaming), and a bare "A:" / "Answer:" /
    /// "Assistant:" label is dropped. Then a "Sure, I can help!" style first line goes too.
    static func stripEcho(_ text: String) -> String {
        var out = text
        let trimmedStart = out.drop(while: { $0.isWhitespace })
        if trimmedStart.hasPrefix("Q:") || trimmedStart.lowercased().hasPrefix("question:") {
            if let answerLabel = out.range(of: #"\n\s*(?:A|Answer):\s*"#, options: .regularExpression) {
                out = String(out[answerLabel.upperBound...])
            } else {
                return ""
            }
        }
        out = out.replacingOccurrences(of: #"\A\s*(?:A|Answer|Assistant):\s*"#, with: "", options: .regularExpression)
        let ns = out as NSString
        if let match = preambleRegex.firstMatch(in: out, range: NSRange(location: 0, length: ns.length)) {
            out = ns.substring(from: match.range.location + match.range.length)
        }
        return out
    }

    /// Markdown emphasis and headings stripped; bullet markers become a bullet character.
    static func stripMarkdown(_ text: String) -> String {
        var out = stripEcho(text).replacingOccurrences(of: "**", with: "")
        out = out.replacingOccurrences(of: "__", with: "")
        let lines = out.components(separatedBy: "\n").map { line -> String in
            var trimmed = Substring(line)
            let leading = trimmed.prefix(while: { $0 == " " })
            trimmed = trimmed.dropFirst(leading.count)
            if trimmed.hasPrefix("#") {
                trimmed = trimmed.drop(while: { $0 == "#" || $0 == " " })
                return String(trimmed)
            }
            if trimmed.hasPrefix("* ") || trimmed.hasPrefix("- ") || trimmed.hasPrefix("\u{2022} ") {
                return String(leading) + "\u{2022} " + trimmed.dropFirst(2)
            }
            return line
        }
        out = lines.joined(separator: "\n")
        while out.contains("\n\n\n") { out = out.replacingOccurrences(of: "\n\n\n", with: "\n\n") }
        return out
    }

    /// Tafsir and surah-background sources are markdown-ish prose: headings, emphasis, links.
    /// Reduced to plain sentences for the model's context.
    static func plainProse(_ text: String) -> String {
        var out = stripMarkdown(text)
        out = out.replacingOccurrences(of: #"\[([^\]]+)\]\([^)]*\)"#, with: "$1", options: .regularExpression)
        out = out.replacingOccurrences(of: "`", with: "")
        out = out.replacingOccurrences(of: "*", with: "")
        out = out.replacingOccurrences(of: #"\s*\n+\s*"#, with: " ", options: .regularExpression)
        out = out.replacingOccurrences(of: #" {2,}"#, with: " ", options: .regularExpression)
        return out.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static let ayahRefRegex = try! NSRegularExpression(pattern: #"(?<![\d:])\d{1,3}\s*:\s*\d{1,3}(?![\d:])"#)
    private static let hadithRefRegex = try! NSRegularExpression(
        pattern: #"(?i)\b(bukhari|bukhaari|muslim|tirmidhi|tirmidhee|nasa'?i|nasaa'?i|abi dawud|abu dawud|abu dawood|ibn majah|ibn maajah|muwatta|malik|musnad|ahmad|darimi|riyad|riyadh|nawawi|qudsi|mishkat|bulugh|shama'?il|adab)\b[^()]{0,40}?\d"#)
    private static let parentheticalRegex = try! NSRegularExpression(pattern: #"\s?\(([^()]{1,160})\)"#)

    /// A quote within ONE line: an unclosed quote must never pair with the next paragraph's opening.
    private static let quotationRegex = try! NSRegularExpression(pattern: #"[\"\u201C]([^\"\u201C\u201D\n]{40,400})[\"\u201D]"#)

    /// Every quotation of six or more words that is not the wording of a passage the model was given
    /// is scripture recalled from memory - the exact thing the on-device model gets wrong. The quote
    /// marks come off and the span is flagged "(wording not verified)"; the count is disclosed.
    static func policeQuotations(_ text: String, passages: [AskAIPassage]) -> (text: String, flagged: Int) {
        guard !text.isEmpty else { return (text, 0) }
        func fold(_ s: String) -> String {
            s.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }.joined(separator: " ")
        }
        let corpus = passages.map { fold($0.text) }
        let ns = text as NSString
        var result = text
        var flagged = 0
        for match in quotationRegex.matches(in: text, range: NSRange(location: 0, length: ns.length)).reversed() {
            let quoted = ns.substring(with: match.range(at: 1))
            let folded = fold(quoted)
            guard folded.split(separator: " ").count >= 6 else { continue }
            if corpus.contains(where: { $0.contains(folded) }) { continue }
            guard let range = Range(match.range, in: result) else { continue }
            result.replaceSubrange(range, with: quoted + " (wording not verified)")
            flagged += 1
        }
        return (result, flagged)
    }

    private static func paragraphKey(_ paragraph: String) -> String {
        paragraph.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }.joined(separator: " ")
    }

    /// True once a completed paragraph (or one of its sentences, for long paragraphs) has appeared
    /// before: the model is looping and nothing after this point will be new.
    static func isLooping(_ text: String) -> Bool {
        let paragraphs = text.components(separatedBy: "\n\n").dropLast()   // the last one is still streaming
        var seen = Set<String>()
        for paragraph in paragraphs {
            let key = paragraphKey(paragraph)
            guard key.count >= 40 else { continue }
            if !seen.insert(key).inserted { return true }
        }
        return false
    }

    /// The text up to (not including) the first repeated paragraph, with the repeat and everything
    /// after it dropped - what a looping answer is worth.
    static func collapsingRepetition(_ text: String) -> String {
        let paragraphs = text.components(separatedBy: "\n\n")
        var kept: [String] = []
        var seen = Set<String>()
        for paragraph in paragraphs {
            let key = paragraphKey(paragraph)
            if key.count >= 40, !seen.insert(key).inserted { break }
            kept.append(paragraph)
        }
        return kept.joined(separator: "\n\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// A trailing "References:" / "Sources:" list is the model restating its citations; the rows
    /// beneath the answer are the references, so the block goes, verified or not.
    static func droppingTrailingReferences(_ text: String) -> String {
        var lines = text.components(separatedBy: "\n")
        lines.removeAll { $0.range(of: #"^\s*(?:[\u2022\-\*]|\d{1,2}[.)])\s*$"#, options: .regularExpression) != nil }
        if let heading = lines.lastIndex(where: {
            $0.range(of: #"(?i)^\s*(?:references|sources|citations)\s*:?\s*$"#, options: .regularExpression) != nil
        }) {
            // Only a TRAILING block: every line after the heading must be a bullet, a bare
            // reference, or blank.
            let tail = lines[(heading + 1)...]
            let isReferenceLine: (String) -> Bool = { line in
                let t = line.trimmingCharacters(in: .whitespaces)
                return t.isEmpty || t.hasPrefix("\u{2022}") || t.hasPrefix("-") || t.hasPrefix("(") || t.hasPrefix("[")
                    || t.contains("http") || t.count <= 60
                    || t.range(of: #"^\d{1,2}[.)]"#, options: .regularExpression) != nil
                    || t.range(of: #"^\d{1,3}:\d{1,3}"#, options: .regularExpression) != nil
            }
            if tail.allSatisfy(isReferenceLine) {
                lines.removeSubrange(heading...)
            }
        }
        var out = lines.joined(separator: "\n")
        while out.contains("\n\n\n") { out = out.replacingOccurrences(of: "\n\n\n", with: "\n\n") }
        return out.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Removes every parenthetical that cites a reference the app did NOT give the model (a verse
    /// number or a hadith number recalled from memory), returning the cleaned text and how many were
    /// removed. A parenthetical is kept when at least one of its references is a real passage.
    static func policeCitations(_ text: String, passages: [AskAIPassage]) -> (text: String, removed: Int) {
        guard !text.isEmpty else { return (text, 0) }
        let verified = passages.map { $0.reference.lowercased() }
        let ns = text as NSString
        var result = text
        var removed = 0
        for match in parentheticalRegex.matches(in: text, range: NSRange(location: 0, length: ns.length)).reversed() {
            let content = ns.substring(with: match.range(at: 1))
            let contentNS = content as NSString
            let contentRange = NSRange(location: 0, length: contentNS.length)
            let citesAyah = ayahRefRegex.firstMatch(in: content, range: contentRange) != nil
            let citesHadith = hadithRefRegex.firstMatch(in: content, range: contentRange) != nil
            guard citesAyah || citesHadith else { continue }
            let lowered = content.lowercased()
            let isVerified = verified.contains { reference in
                guard let range = lowered.range(of: reference) else { return false }
                let before = range.lowerBound > lowered.startIndex ? lowered[lowered.index(before: range.lowerBound)] : " "
                let after = range.upperBound < lowered.endIndex ? lowered[range.upperBound] : " "
                return !before.isNumber && !after.isNumber
            }
            if isVerified { continue }
            if let swiftRange = Range(match.range, in: result) {
                result.removeSubrange(swiftRange)
                removed += 1
            }
        }
        if removed > 0 {
            result = result.replacingOccurrences(of: " .", with: ".")
            result = result.replacingOccurrences(of: " ,", with: ",")
            result = result.replacingOccurrences(of: #" {2,}"#, with: " ", options: .regularExpression)
            // A "References:" list whose items were all recalled references is now a heading over
            // empty bullets: drop the bullets, then the heading if nothing is left under it.
            var lines = result.components(separatedBy: "\n")
            lines.removeAll { $0.range(of: #"^\s*(?:[\u2022\-\*]|\d{1,2}[.)])\s*$"#, options: .regularExpression) != nil }
            while let last = lines.last(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }),
                  last.range(of: #"(?i)^\s*(?:references|sources|citations)\s*:?\s*$"#, options: .regularExpression) != nil,
                  let index = lines.lastIndex(of: last) {
                lines.removeSubrange(index...)
            }
            result = lines.joined(separator: "\n")
            while result.contains("\n\n\n") { result = result.replacingOccurrences(of: "\n\n\n", with: "\n\n") }
            result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return (result, removed)
    }
}

// MARK: - Conversation

/// The running conversation - ONE for the app, so reopening the chat from any entry point continues
/// where it left off (until "New conversation"). Every turn retrieves fresh passages for ITS question
/// and re-sends the recent transcript, so follow-ups keep their thread within the model's window.
@MainActor
final class AskAIConversation: ObservableObject {
    static let shared = AskAIConversation()

    enum Role { case user, assistant }

    struct Message: Identifiable {
        let id = UUID()
        let role: Role
        var text: String
        /// The passages retrieved for this turn (assistant only): the pool citations resolve from, so
        /// a cited row can never point at something the model was not shown.
        var passages: [AskAIPassage] = []
        var isStreaming = false
        var failed = false
        /// References the model recalled from memory that were removed at the end of the turn
        /// (`AskAIAnswerText.policeCitations`) - disclosed beneath the answer.
        var removedCitations = 0
        /// Quotations that matched no passage's wording and were marked "(wording not verified)".
        var flaggedQuotations = 0
        /// The question asked for a ruling (halal/haram/allowed): the reply carries a fixed note that
        /// no answer here is one, whatever the model wrote.
        var asksForRuling = false

        /// The passages the answer actually cites, in the order they first appear. Parsed off the live
        /// text, so the rows stay in lockstep with whatever the answer says as it streams. A surah
        /// passage counts as cited when the answer names the surah; a tafsir excerpt never gets its
        /// own row (its ayah's row opens the reader, where the tafsir lives).
        var citedPassages: [AskAIPassage] {
            guard role == .assistant, !text.isEmpty, !passages.isEmpty else { return [] }
            // "(Sahih al-Bukhari, 6114)", "Sahih Muslim no. 8a" - the reference with its
            // punctuation and "no." variants folded to the app's own "Book Number" form.
            let lowered = text.lowercased()
                .replacingOccurrences(of: ",", with: "")
                .replacingOccurrences(of: #"\s+(?:no\.?|number|#)\s*"#, with: " ", options: .regularExpression)
            var positions: [(position: Int, passage: AskAIPassage)] = []
            for passage in passages {
                if passage.isSubject {
                    positions.append((-1, passage))
                    continue
                }
                let reference = passage.reference.lowercased()
                var searchStart = lowered.startIndex
                while let range = lowered.range(of: reference, range: searchStart..<lowered.endIndex) {
                    // A whole reference only: "2:15" must not claim "2:153", nor "Bukhari 61" claim "Bukhari 6114".
                    let before = range.lowerBound > lowered.startIndex ? lowered[lowered.index(before: range.lowerBound)] : " "
                    let after = range.upperBound < lowered.endIndex ? lowered[range.upperBound] : " "
                    if !before.isNumber, !after.isNumber {
                        positions.append((lowered.distance(from: lowered.startIndex, to: range.lowerBound), passage))
                        break
                    }
                    searchStart = range.upperBound
                }
            }
            return positions.sorted { $0.position < $1.position }.map(\.passage)
        }
    }

    @Published private(set) var messages: [Message] = []
    @Published private(set) var isAnswering = false
    private var task: Task<Void, Never>?

    private init() {}

    /// The completed question/answer pairs so far, oldest first - what a new turn is re-grounded on.
    private func completedTurns() -> [OnDeviceAsk.SummarizeTurn] {
        var turns: [OnDeviceAsk.SummarizeTurn] = []
        var pendingQuestion: String?
        for message in messages {
            switch message.role {
            case .user:
                pendingQuestion = message.text
            case .assistant:
                if let question = pendingQuestion, !message.failed, !message.isStreaming, !message.text.isEmpty {
                    turns.append(.init(question: question, answer: message.text))
                }
                pendingQuestion = nil
            }
        }
        return turns
    }

    func ask(_ question: String) {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, OnDeviceAsk.isAvailable else { return }
        cancel()
        let transcript = completedTurns()
        let previousQuestion = messages.last(where: { $0.role == .user })?.text
        let carried = messages.last(where: { $0.role == .assistant })?.citedPassages ?? []
        messages.append(Message(role: .user, text: trimmed))
        messages.append(Message(role: .assistant, text: "", isStreaming: true, asksForRuling: Self.asksForRuling(trimmed)))
        isAnswering = true

        task = Task { @MainActor in
            let passages = await AskAIRetriever.passages(for: trimmed, previousQuestion: previousQuestion, carried: carried)
            guard !Task.isCancelled else { return }
            updateReply { $0.passages = passages }
            await answer(question: trimmed, passages: passages, transcript: transcript)
        }
    }

    #if canImport(FoundationModels)
    private func answer(question: String, passages: [AskAIPassage], transcript: [OnDeviceAsk.SummarizeTurn]) async {
        guard #available(iOS 26.0, *) else { finishReply(failed: true); return }
        var sources = passages.map(\.source)
        var turns = transcript
        var prompt = question
        var retriedForContext = false
        var retriedForGuardrail = false
        while true {
            do {
                for try await text in OnDeviceAsk.streamChatAnswer(question: prompt, sources: sources, transcript: turns) {
                    guard !Task.isCancelled else { return }
                    let cleaned = AskAIAnswerText.stripMarkdown(text)
                    updateReply { $0.text = cleaned }
                    // A small model can fall into repeating itself until the token ceiling: the
                    // moment a paragraph comes back, the answer is over.
                    if AskAIAnswerText.isLooping(cleaned) { break }
                }
                guard !Task.isCancelled else { return }
                finishReply(failed: false)
                return
            } catch {
                guard !Task.isCancelled else { return }
                // The window overflowed (a long transcript on top of long passages): once, retry
                // lean - the question with a few passages and no history - rather than dead-end.
                if !retriedForContext, OnDeviceAsk.isContextOverflow(error) {
                    retriedForContext = true
                    sources = Array(sources.prefix(3))
                    turns = []
                    updateReply { $0.text = "" }
                    continue
                }
                // Apple's guardrail trips on ordinary religious topics (war, punishment, death).
                // Once, re-ask with the question framed as the educational request it is.
                if !retriedForGuardrail, OnDeviceAsk.isGuardrail(error) {
                    retriedForGuardrail = true
                    prompt = "For an educational explanation of Islamic teaching and scripture: \(question)"
                    updateReply { $0.text = "" }
                    continue
                }
                finishReply(failed: true, message: OnDeviceAsk.failureMessage(for: error))
                return
            }
        }
    }
    #else
    private func answer(question: String, passages: [AskAIPassage], transcript: [OnDeviceAsk.SummarizeTurn]) async {
        finishReply(failed: true, message: nil)
    }
    #endif

    private static let rulingRegex = try! NSRegularExpression(
        pattern: #"(?i)\b(?:haram|halal|haraam|halaal|permissible|permitted|allowed|forbidden|prohibited|makruh|makrooh|obligatory|wajib|fard|sinful|a sin|is it ok|is it okay|can i|am i allowed|may i)\b|حرام|حلال|يجوز|جائز"#)

    /// Whether the question asks for a verdict. The instructions already tell the model to describe
    /// the views and defer, but a fixed note is not something a small model can forget.
    static func asksForRuling(_ question: String) -> Bool {
        rulingRegex.firstMatch(in: question, range: NSRange(location: 0, length: (question as NSString).length)) != nil
    }

    private func updateReply(_ change: (inout Message) -> Void) {
        guard let index = messages.indices.last, messages[index].role == .assistant else { return }
        change(&messages[index])
    }

    /// Settles the reply. A success is policed for recalled citations; a failure with nothing
    /// streamed shows the reason (or a generic line), and a failure MID-answer keeps what streamed
    /// but says plainly that it stopped early - a sentence that just ends looked like the answer.
    private func finishReply(failed: Bool, message: String? = nil) {
        updateReply { reply in
            reply.isStreaming = false
            if failed {
                reply.failed = true
                if reply.text.isEmpty {
                    reply.text = message ?? "I couldn\u{2019}t answer that right now. Try rephrasing the question, or ask again in a moment."
                } else {
                    reply.text += "\n\n(" + (message ?? "The answer stopped early. Ask again to continue.") + ")"
                }
            } else {
                let policed = AskAIAnswerText.policeCitations(AskAIAnswerText.collapsingRepetition(reply.text), passages: reply.passages)
                let quoted = AskAIAnswerText.policeQuotations(policed.text, passages: reply.passages)
                reply.text = AskAIAnswerText.droppingTrailingReferences(quoted.text)
                reply.removedCitations = policed.removed
                reply.flaggedQuotations = quoted.flagged
            }
        }
        isAnswering = false
        #if DEBUG
        debugLogLastTurn(failed: failed)
        #endif
    }

    #if DEBUG
    /// Headless verification: with `-askAILog`, every finished turn is appended to
    /// Documents/askai-log.txt (question, the retrieved references, the answer) so the whole answer
    /// can be read from the simulator's app container instead of a screenshot of its tail.
    private func debugLogLastTurn(failed: Bool) {
        guard ProcessInfo.processInfo.arguments.contains("-askAILog"),
              let reply = messages.last, reply.role == .assistant,
              let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let question = messages.dropLast().last(where: { $0.role == .user })?.text ?? ""
        let entry = """
        ===== Q: \(question)
        PASSAGES: \(reply.passages.map(\.reference).joined(separator: " | "))
        CITED: \(reply.citedPassages.map(\.reference).joined(separator: " | "))
        FAILED: \(failed)
        A: \(reply.text)

        """
        let url = documents.appendingPathComponent("askai-log.txt")
        if let handle = try? FileHandle(forWritingTo: url) {
            handle.seekToEndOfFile()
            handle.write(Data(entry.utf8))
            handle.closeFile()
        } else {
            try? entry.write(to: url, atomically: true, encoding: .utf8)
        }
    }
    #endif

    /// Stops a running answer, keeping whatever streamed so far (an empty reply is dropped with its
    /// question, so a stopped ask leaves no half-turn behind).
    func cancel() {
        task?.cancel()
        task = nil
        guard isAnswering else { return }
        isAnswering = false
        if let index = messages.indices.last, messages[index].role == .assistant, messages[index].isStreaming {
            if messages[index].text.isEmpty {
                messages.removeLast()
                if messages.last?.role == .user { messages.removeLast() }
            } else {
                messages[index].isStreaming = false
            }
        }
    }

    func reset() {
        cancel()
        messages = []
    }
}

// MARK: - The chat screen

@available(iOS 16.0, *)
struct AskAIChatView: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject private var chat = AskAIConversation.shared
    @Environment(\.dismiss) private var dismiss

    /// Asked as soon as the screen appears (the search screens hand their query in), unless it is
    /// already the conversation's latest question - reopening the sheet must not ask twice.
    var initialQuestion: String? = nil
    var presentedAsSheet = false

    @State private var draft = ""
    @FocusState private var inputFocused: Bool
    /// The initial question is asked once per presentation: `onAppear` fires again every time a
    /// cited row's pushed reader pops, and that must not re-ask the search query.
    @State private var askedInitial = false
    /// Whether the transcript keeps pinning its bottom as text streams. A reader who scrolls up to
    /// re-read stops being dragged back down; reaching the bottom again (or a new turn) re-arms it.
    @State private var followsStream = true
    #if DEBUG
    /// `-askAI "q1||q2||q3"`: the remaining questions, asked one at a time as each answer settles.
    @State private var debugQueue: [String] = []
    #endif

    private static let starters = [
        "What does the Quran say about patience in hardship?",
        "How do I make up a missed prayer?",
        "Why is Surah Al-Kahf read on Fridays?",
        "What did the Prophet say about kindness to parents?",
    ]

    var body: some View {
        Group {
            if OnDeviceAsk.isAvailable {
                conversation
            } else {
                unavailable
            }
        }
        .navigationTitle("Ask AI")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if presentedAsSheet {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        settings.hapticFeedback()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                    }
                    .tint(settings.accentColor.accent1)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    settings.hapticFeedback()
                    // The transcript is cleared; a typed-but-unsent draft is the reader's, and stays.
                    chat.reset()
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .disabled(chat.messages.isEmpty)
                .accessibilityLabel("New conversation")
                .tint(settings.accentColor.accent1)
            }
        }
        #if DEBUG
        .onChange(of: chat.isAnswering) { answering in
            guard !answering, !debugQueue.isEmpty else { return }
            let next = debugQueue.removeFirst()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { chat.ask(next) }
        }
        #endif
        .onAppear {
            if #available(iOS 26.0, *) { OnDeviceAsk.prewarmChatModel() }
            guard !askedInitial else { return }
            askedInitial = true
            var question = initialQuestion?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            #if DEBUG
            // Headless verification: `-askAI "<question>"` asks it the moment the screen appears (pair
            // with `-launchTabIslam -islamDestination askAI`); "q1||q2" asks the rest one by one as
            // each answer settles, so follow-ups can be exercised too. DEBUG builds only.
            if question.isEmpty,
               let index = ProcessInfo.processInfo.arguments.firstIndex(of: "-askAI"),
               ProcessInfo.processInfo.arguments.indices.contains(index + 1) {
                let parts = ProcessInfo.processInfo.arguments[index + 1]
                    .components(separatedBy: "||")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                question = parts.first ?? ""
                debugQueue = Array(parts.dropFirst())
            }
            #endif
            guard !question.isEmpty else { return }
            if chat.messages.last(where: { $0.role == .user })?.text != question {
                chat.ask(question)
            }
        }
    }

    private var conversation: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    if chat.messages.isEmpty {
                        welcome
                    }
                    ForEach(chat.messages) { message in
                        messageView(message)
                            .id(message.id)
                    }
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                        .onAppear { followsStream = true }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            // A deliberate drag means the reader is reading: stop pinning the bottom until they
            // reach it again (the sentinel's onAppear) or a new turn starts.
            .simultaneousGesture(DragGesture(minimumDistance: 12).onChanged { _ in followsStream = false })
            .onChange(of: chat.messages.count) { _ in
                followsStream = true
                withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: chat.messages.last?.text) { _ in
                guard followsStream else { return }
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
        .safeAreaInset(edge: .bottom) { inputBar }
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                Text("Ask anything about Islam")
            }
            .font(.headline)
            .foregroundStyle(settings.accentColor.color)

            Text("A question, a follow-up, a \u{201C}what does this mean\u{201D}: the answer comes from Apple Intelligence on your device, and your prayer times and the app's own articles are cited beneath each reply, ready to open. Nothing leaves your phone.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Label("This is a machine, not a scholar. It is here for quick, simple, general questions, and it can be confidently wrong. It does not give rulings, it is never the final answer, and anything that actually matters belongs with a knowledgeable scholar of Ahl as-Sunnah wa al-Jama\u{2018}ah.", systemImage: "exclamationmark.triangle")
                .font(.footnote)
                .foregroundStyle(.secondary)

            // How it works, in the app itself: a reader who knows the model cannot quote scripture
            // and cannot invent a reference can judge what they are reading. Kept to four lines.
            VStack(alignment: .leading, spacing: 6) {
                Text("HOW IT WORKS")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text("Your question first searches this app's own prayer times and Islam articles. What it finds is handed to Apple Intelligence running on your device, which answers in its own words and cites what it used.\n\nIt is not allowed to write out a verse or a hadith, and not allowed to cite a reference the app did not give it: anything it invents is stripped out before you see it, and a quotation that matches nothing is marked \u{201C}wording not verified\u{201D}. Every citation becomes a row beneath the answer that opens the real source, so you can always check it yourself.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Self.starters, id: \.self) { question in
                    Button {
                        settings.hapticFeedback()
                        chat.ask(question)
                    } label: {
                        HStack(spacing: 8) {
                            Text(question)
                                .font(.subheadline)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.up.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .conditionalGlassEffect(clear: true, rectangle: true)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func messageView(_ message: AskAIConversation.Message) -> some View {
        switch message.role {
        case .user:
            HStack {
                Spacer(minLength: 48)
                Text(message.text)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(settings.accentColor.color.opacity(0.2))
                    )
            }
        case .assistant:
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                    Text("AI")
                        .font(.caption.weight(.semibold))
                    if message.isStreaming {
                        ProgressView()
                            .controlSize(.mini)
                    }
                    Spacer()
                }
                .foregroundStyle(settings.accentColor.color)

                if message.text.isEmpty {
                    Text(message.passages.isEmpty ? "Looking through your prayer times and the app\u{2019}s articles\u{2026}" : "Thinking\u{2026}")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if message.failed, message.passages.isEmpty || !message.text.contains("\n\n(") {
                    Text(message.text)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    SelectableProse(text: message.text, textStyle: .subheadline)
                }

                let cited = message.citedPassages
                if !cited.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(cited) { passage in
                            passageRow(passage)
                        }
                    }
                }

                if message.removedCitations > 0 {
                    Text(message.removedCitations == 1
                         ? "1 reference the AI recalled from memory was removed because it is not among the passages it was given."
                         : "\(message.removedCitations) references the AI recalled from memory were removed because they are not among the passages it was given.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if message.flaggedQuotations > 0 {
                    Text(message.flaggedQuotations == 1
                         ? "1 quotation does not match any passage the AI was given and is marked \u{201C}wording not verified\u{201D}: treat it as a paraphrase at best."
                         : "\(message.flaggedQuotations) quotations do not match any passage the AI was given and are marked \u{201C}wording not verified\u{201D}: treat them as paraphrases at best.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // On EVERY finished answer, not only the ruling-shaped ones. A caution that appears
                // selectively teaches the reader that its absence means "this one is reliable",
                // which is the opposite of true: the model is a machine that can be confidently
                // wrong about anything, so the caution belongs under everything it says.
                if !message.isStreaming, !message.failed {
                    Label(message.asksForRuling
                          ? "Not a ruling, and scholars differ on questions like this. This is AI: useful for quick, simple, general questions, never the final word. For your own situation ask a knowledgeable scholar of Ahl as-Sunnah."
                          : "This is AI: useful for quick, simple, general questions, never the final word. For anything that matters, ask a knowledgeable scholar of Ahl as-Sunnah.",
                          systemImage: "exclamationmark.triangle")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .conditionalGlassEffect(clear: true, rectangle: true)
        }
    }

    /// A cited passage as a real row: the article reopens at the page the answer drew on.
    @ViewBuilder
    private func passageRow(_ passage: AskAIPassage) -> some View {
        switch passage.kind {
        case .article(let id):
            if let destination = IslamArticles.destination(for: id) {
                NavigationLink {
                    destination
                } label: {
                    passageLabel(title: passage.reference, text: passage.text)
                }
                .buttonStyle(.plain)
            }
        case .prayer:
            // No link: the times ARE the passage, and they are already on the app's first screen.
            passageLabel(title: passage.reference, text: passage.text)
        }
    }

    private func passageLabel(title: String, text: String) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(settings.accentColor.color)
                Text(text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.secondary.opacity(0.1))
        )
        .contentShape(Rectangle())
    }

    private var inputBar: some View {
        VStack(spacing: 6) {
            HStack(alignment: .bottom, spacing: 8) {
                TextField("Ask about prayer or Islam", text: $draft, axis: .vertical)
                    .lineLimit(1...5)
                    .focused($inputFocused)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .conditionalGlassEffect(clear: true)

                if chat.isAnswering {
                    Button {
                        settings.hapticFeedback()
                        chat.cancel()
                    } label: {
                        Image(systemName: "stop.circle.fill")
                            .font(.title)
                    }
                    .accessibilityLabel("Stop answering")
                } else {
                    Button {
                        send()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title)
                    }
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityLabel("Send")
                }
            }
            .tint(settings.accentColor.color)

            Text("Apple Intelligence, on device. Answers can be wrong and are never a religious ruling.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(.bar)
    }

    private func send() {
        let question = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }
        settings.hapticFeedback()
        draft = ""
        chat.ask(question)
    }

    private var unavailable: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(settings.accentColor.color)
            Text("Ask AI needs Apple Intelligence")
                .font(.headline)
            Text("Ask AI runs entirely on your device with Apple Intelligence, which needs iOS 26 on a supported iPhone with Apple Intelligence turned on in Settings.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// The chat presented as a sheet (from the search screens), in its own navigation stack so the cited
/// rows can push the reader.
@available(iOS 16.0, *)
struct AskAIChatSheet: View {
    var initialQuestion: String? = nil

    var body: some View {
        NavigationStack {
            AskAIChatView(initialQuestion: initialQuestion, presentedAsSheet: true)
        }
    }
}

#endif
