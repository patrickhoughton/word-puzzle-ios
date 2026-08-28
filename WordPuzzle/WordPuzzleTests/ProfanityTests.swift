import Testing
@testable import WordPuzzle
import Foundation

struct ProfanityTests {

    @Test func testBlockedWordsNotInWordList() async throws {
        // Load the word list
        let wl = WordList()
        await wl.load()
        #expect(wl.isLoaded == true)

        // Load ldnoobw-en.txt from the test bundle
        guard let blocklistURL = Bundle(for: ProfanityTestsHelper.self).url(forResource: "ldnoobw-en", withExtension: "txt") else {
            Issue.record("ldnoobw-en.txt not found in test bundle — copy it to WordPuzzleTests/ directory")
            return
        }

        let blocklistContent = try String(contentsOf: blocklistURL, encoding: .utf8)
        // Filter to single-token words >=4 letters only (to match the word set)
        let blocklist = Set(
            blocklistContent
                .components(separatedBy: .newlines)
                .map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && !$0.contains(" ") && $0.count >= 4 }
        )

        #expect(!blocklist.isEmpty, "Blocklist should not be empty")
        #expect(wl.words.isDisjoint(with: blocklist), "Word list contains blocked words!")
    }
}

// Helper class so we can call Bundle(for:) from a struct test context
class ProfanityTestsHelper {}
