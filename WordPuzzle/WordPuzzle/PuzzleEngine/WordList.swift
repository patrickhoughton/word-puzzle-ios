import Foundation
import Observation

@Observable
final class WordList {
    private(set) var words: Set<String> = []
    private(set) var pangramWords: [String] = []
    private(set) var isLoaded: Bool = false

    func load() async {
        guard let url = Bundle.main.url(forResource: "enable-clean", withExtension: "txt") else {
            assertionFailure("enable-clean.txt not found in app bundle")
            return
        }

        // Read and parse on a background thread
        let (loadedWords, loadedPangrams) = await Task.detached(priority: .userInitiated) {
            guard let content = try? String(contentsOf: url, encoding: .utf8) else {
                return (Set<String>(), [String]())
            }

            let filtered = content
                .components(separatedBy: .newlines)
                .map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
                .filter { $0.count >= 4 }

            let wordSet = Set(filtered)

            // Pitfall 5 (locked): compute pangram pool ONCE during load, never inside generatePuzzle
            let pangrams = filtered.filter { Set($0).count == 7 && $0.count >= 7 }

            return (wordSet, pangrams)
        }.value

        await MainActor.run {
            self.words = loadedWords
            self.pangramWords = loadedPangrams
            self.isLoaded = true
        }
    }

    /// O(1) Set lookup — D-08 (locked): never use Array.contains
    func contains(_ word: String) -> Bool {
        words.contains(word.lowercased())
    }
}
