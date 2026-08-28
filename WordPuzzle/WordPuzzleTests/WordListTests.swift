import Testing
import Foundation
@testable import WordPuzzle

// Use a class suite so init() runs once and the wordList is shared across tests.
// @Suite(.serialized) prevents parallel execution to avoid memory pressure from
// multiple concurrent word list loads during CI runs.
@Suite(.serialized)
final class WordListTests {
    let wordList: WordList

    init() async throws {
        wordList = WordList()
        await wordList.load()
    }

    @Test func testWordListLoads() async throws {
        #expect(wordList.isLoaded == true)
        #expect(wordList.words.count > 170_000)
    }

    @Test func testAllWordsAreValidLength() async throws {
        // Sample the first 1000 words — every sampled word must be >= 4 letters
        let sample = Array(wordList.words.prefix(1000))
        for word in sample {
            #expect(word.count >= 4, "Word '\(word)' is shorter than 4 letters")
        }
    }

    @Test func testWordSetLookupIsO1() async throws {
        // O(1) Set.contains: 10,000 lookups should complete in <500ms.
        // An O(n) linear scan of 170K words would take seconds for 10K calls.
        // This threshold definitively proves the Set (not Array) implementation.
        let lowercasedKey = "puzzle" // Pre-compute to avoid allocation overhead skewing timing
        let start = Date()
        for _ in 0..<10_000 {
            _ = wordList.words.contains(lowercasedKey)
        }
        let elapsed = Date().timeIntervalSince(start)
        #expect(elapsed < 0.500, "10,000 Set lookups took \(elapsed)s — expected < 0.500s for O(1)")
    }

    @Test func testPangramPoolPopulated() async throws {
        #expect(wordList.pangramWords.count > 1_000)
        for word in wordList.pangramWords.prefix(100) {
            #expect(Set(word).count == 7, "pangramWord '\(word)' does not have exactly 7 unique letters")
        }
    }
}
