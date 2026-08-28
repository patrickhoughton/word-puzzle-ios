import Testing
import Foundation
@testable import WordPuzzle

@MainActor
@Suite struct ScoreCalculatorTests {

    @Test func testFourLetterWordScoresOnePoint() {
        #expect(ScoreCalculator.points(for: "cake", isPangram: false) == 1)
    }

    @Test func testLongerWordScoresItsLength() {
        #expect(ScoreCalculator.points(for: "cakes", isPangram: false) == 5)
        #expect(ScoreCalculator.points(for: "cathode", isPangram: false) == 7)
    }

    @Test func testPangramAddsSevenPointBonus() {
        #expect(ScoreCalculator.points(for: "cathode", isPangram: true) == 14)
    }

    @Test func testWordsBelowFourLettersScoreZero() {
        #expect(ScoreCalculator.points(for: "cat", isPangram: false) == 0)
        #expect(ScoreCalculator.points(for: "", isPangram: false) == 0)
    }

    @Test func testSessionScoreSumsAllWords() {
        // 1 (cake) + 5 (cakes) + 14 (cathode, pangram) = 20
        let total = ScoreCalculator.score(
            for: ["cake", "cakes", "cathode"],
            pangrams: ["cathode"]
        )
        #expect(total == 20)
        #expect(ScoreCalculator.score(for: [], pangrams: []) == 0)
    }
}
