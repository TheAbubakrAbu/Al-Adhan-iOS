import Foundation

/// Where an article's `ScriptureQuote(quran:)` gets its words in this app, which compiles the same
/// article files and the same Dua screen as Al-Islam but ships no Quran: `QuranQuotes.json.deflate`,
/// the cited ayahs alone, cut from Al-Islam's own Quran at build time by
/// Scripts/build_quran_quotes_pack.py and gated byte-identical to a fresh build by that script's
/// `--check`. Al-Islam reads the same references straight out of `QuranData`.
///
/// Saheeh International throughout, which is the translation this app's articles name as their
/// source ("the app's own Hafs text with the Saheeh International translation"). Al-Islam lets the
/// reader choose between Saheeh and Mustafa Khattab because its Quran tab has that setting; this app
/// has no Quran tab and no such setting, so the pack carries the one translation and nothing has to
/// decide at runtime.
enum QuranQuoteSource {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var rows: [String: [String]]?

    /// The quoted text once the pack has been read (a lock, no I/O): safe on the main actor.
    static func resolve(_ reference: QuranQuoteReference) -> QuranQuoteText? {
        lock.lock()
        let loaded = rows
        lock.unlock()
        guard let loaded else {
            // Not read yet. The caller's `.task` awaits `waitUntilReady()` and asks again.
            return nil
        }
        return text(reference, in: loaded)
    }

    /// Reads the pack off the main actor, once. Article views await this before their second ask.
    static func waitUntilReady() async {
        lock.lock()
        let already = rows != nil
        lock.unlock()
        guard !already else { return }
        let loaded = await Task.detached(priority: .userInitiated) { load() }.value
        lock.lock()
        if rows == nil { rows = loaded }
        lock.unlock()
    }

    private static func text(_ reference: QuranQuoteReference, in rows: [String: [String]]) -> QuranQuoteText? {
        guard let strings = rows[reference.text], strings.count == 2 else { return nil }
        return QuranQuoteText(arabic: strings[0], english: strings[1])
    }

    private static func load() -> [String: [String]] {
        guard let url = Bundle.main.url(forResource: "QuranQuotes", withExtension: "json.deflate")
                ?? Bundle.main.url(forResource: "QuranQuotes", withExtension: "json.deflate", subdirectory: "Data/Islam")
                ?? Bundle.main.url(forResource: "QuranQuotes", withExtension: "json.deflate", subdirectory: "Islam"),
              let compressed = try? Data(contentsOf: url),
              let json = IslamArticles.inflate(compressed),
              let root = try? JSONSerialization.jsonObject(with: json) as? [String: Any],
              root["version"] as? Int == 1,
              let packed = root["rows"] as? [String: [String]] else { return [:] }
        return packed
    }
}
