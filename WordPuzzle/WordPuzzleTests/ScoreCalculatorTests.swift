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

    @Test func testPangramBonusPerWordIsSeven() {
        #expect(ScoreCalculator.pangramBonusPerWord == 7)
    }

    @Test func testSweepBonusIsSevenPerPangram() {
        #expect(ScoreCalculator.sweepBonus(pangramCount: 0) == 0)
        #expect(ScoreCalculator.sweepBonus(pangramCount: 1) == 7)
        #expect(ScoreCalculator.sweepBonus(pangramCount: 3) == 21)
        #expect(ScoreCalculator.sweepBonus(pangramCount: 40) == 280)
        #expect(ScoreCalculator.sweepBonus(pangramCount: -1) == 0)
    }

    @Test func testLengthCompletionBonusEqualsLength() {
        #expect(ScoreCalculator.lengthCompletionBonus(length: 4) == 4)
        #expect(ScoreCalculator.lengthCompletionBonus(length: 5) == 5)
        #expect(ScoreCalculator.lengthCompletionBonus(length: 8) == 8)
        #expect(ScoreCalculator.lengthCompletionBonus(length: 3) == 0)
    }
}
