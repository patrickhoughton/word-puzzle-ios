import Testing
@testable import WordPuzzle

@Suite struct RankTierTests {

    @Test func testTierBoundariesAgainstMax100() {
        #expect(RankTier.tier(score: 0, maxScore: 100) == .novice)
        #expect(RankTier.tier(score: 1, maxScore: 100) == .novice)
        #expect(RankTier.tier(score: 2, maxScore: 100) == .rookie)
        #expect(RankTier.tier(score: 5, maxScore: 100) == .apprentice)
        #expect(RankTier.tier(score: 8, maxScore: 100) == .wordsmith)
        #expect(RankTier.tier(score: 15, maxScore: 100) == .adept)
        #expect(RankTier.tier(score: 25, maxScore: 100) == .skilled)
        #expect(RankTier.tier(score: 40, maxScore: 100) == .expert)
        #expect(RankTier.tier(score: 50, maxScore: 100) == .virtuoso)
        #expect(RankTier.tier(score: 69, maxScore: 100) == .virtuoso)
        #expect(RankTier.tier(score: 70, maxScore: 100) == .master)
        #expect(RankTier.tier(score: 99, maxScore: 100) == .master)
        #expect(RankTier.tier(score: 100, maxScore: 100) == .legend)
        #expect(RankTier.tier(score: 150, maxScore: 100) == .legend)
    }

    @Test func testZeroMaxScoreDoesNotDivideByZero() {
        #expect(RankTier.tier(score: 10, maxScore: 0) == .novice)
        #expect(RankTier.tier(score: 0, maxScore: 0) == .novice)
    }

    @Test func testThresholdsRoundDown() {
        // 2% of 50 == 1.0 -> 1 point required for Rookie
        #expect(RankTier.rookie.requiredScore(maxScore: 50) == 1)
        #expect(RankTier.tier(score: 1, maxScore: 50) == .rookie)
        // 5% of 50 == 2.5 -> rounds down to 2
        #expect(RankTier.apprentice.requiredScore(maxScore: 50) == 2)
    }

    @Test func testDisplayNamesMatchD09Exactly() {
        #expect(RankTier.allCases.count == 10)
        #expect(RankTier.allCases.map(\.displayName) == [
            "Novice", "Rookie", "Apprentice", "Wordsmith", "Adept",
            "Skilled", "Expert", "Virtuoso", "Master", "Legend"
        ])
    }

    @Test func testThresholdPercentagesMatchD09Exactly() {
        #expect(RankTier.allCases.map(\.thresholdPercent) == [0, 2, 5, 8, 15, 25, 40, 50, 70, 100])
    }
}
