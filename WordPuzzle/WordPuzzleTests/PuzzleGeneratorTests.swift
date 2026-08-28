import Testing
import Foundation
@testable import WordPuzzle

// @Suite(.serialized) so the shared WordList is loaded once sequentially,
// avoiding memory pressure from parallel loads.
@Suite(.serialized)
final class PuzzleGeneratorTests {
    let wordList: WordList

    init() async throws {
        wordList = WordList()
        await wordList.load()
    }

    @Test func testGenerates100ValidPuzzles() async throws {
        for i in 0..<100 {
            let puzzle = try generatePuzzle(from: wordList)
            #expect(puzzle.validWords.count >= 20,
                    "Puzzle \(i): expected >= 20 valid words, got \(puzzle.validWords.count)")
            #expect(puzzle.hasPangram == true,
                    "Puzzle \(i): expected at least one pangram")
        }
    }

    @Test func testPangramGuarantee() async throws {
        let puzzle = try generatePuzzle(from: wordList)
        let hasRealPangram = puzzle.pangrams.contains { Set($0) == puzzle.letters }
        #expect(hasRealPangram, "No pangram word found that uses exactly all 7 puzzle letters")
    }

    @Test func testPuzzleLetterInvariants() async throws {
        let puzzle = try generatePuzzle(from: wordList)
        #expect(puzzle.letters.count == 7, "Puzzle should have exactly 7 unique letters")
        for word in puzzle.validWords {
            #expect(word.count >= 4, "'\(word)' is shorter than 4 letters")
            #expect(word.contains(puzzle.centerLetter),
                    "'\(word)' does not contain center letter '\(puzzle.centerLetter)'")
            #expect(Set(word).isSubset(of: puzzle.letters),
                    "'\(word)' uses letters outside the puzzle set")
        }
    }

    @Test func testEmptyWordListThrows() async throws {
        // Create a word list with no words loaded (isLoaded stays false, pangramWords empty)
        let emptyList = WordList()
        // pangramWords will be empty since we never called load()
        #expect(throws: GeneratorError.emptyWordList) {
            try generatePuzzle(from: emptyList)
        }
    }
}
