import Testing
import Foundation
@testable import WordPuzzle

@MainActor
@Suite struct StatsViewTests {
    @Test func testCopyIsFrozen() {
        #expect(StatsView.title == "Stats")
        #expect(StatsView.doneButtonLabel == "Done")
        #expect(StatsView.entryAccessibilityLabel == "Stats")
        #expect(StatsView.nudgeText == "Finish a round to start your stats!")
        #expect(StatsView.streakSuffix == "day streak")
        #expect(StatsView.zeroStreakHeadline == "Start a streak today!")
        #expect(StatsView.atRiskHint == "Play today to keep it!")
        #expect(StatsView.todayHeader == "TODAY")
        #expect(StatsView.lifetimeHeader == "LIFETIME")
        #expect(StatsView.puzzlesTodayCaption == "Puzzles today")
        #expect(StatsView.todayScoreCaption == "Score")
        #expect(StatsView.wordsFoundCaption == "Words found")
        #expect(StatsView.bestScoreCaption == "Best score")
        #expect(StatsView.gamesPlayedCaption == "Games played")
        #expect(StatsView.averageScoreCaption == "Average score")
        #expect(StatsView.averageWordsCaption == "Avg words / game")
        #expect(StatsView.pangramsCaption == "Pangrams found")
        #expect(StatsView.sweepsCaption == "Pangram sweeps")
        #expect(StatsView.bestRankCaption == "Best rank")
        #expect(StatsView.emptyValue == "—")
        #expect(StatsView.notAvailableSpoken == "not available")
        #expect(StatsView.todaySectionSpoken == "Today")
        #expect(StatsView.lifetimeSectionSpoken == "Lifetime")
    }

    @Test func testValueText() {
        #expect(StatsView.valueText(nil) == "—")
        #expect(StatsView.valueText(142) == "142")
    }

    @Test func testStreakHeadline() {
        #expect(StatsView.streakHeadline(currentStreak: 4) == "4 day streak")
        #expect(StatsView.streakHeadline(currentStreak: 1) == "1 day streak")
        #expect(StatsView.streakHeadline(currentStreak: 0) == "Start a streak today!")
    }

    @Test func testLongestLine() {
        #expect(StatsView.longestLine(longestStreak: 12) == "Longest: 12")
        #expect(StatsView.longestLine(longestStreak: 0) == nil)
    }

    @Test func testStreakHint() {
        #expect(StatsView.streakHint(PlayerStats(currentStreak: 4, streakAtRisk: true)) == "Play today to keep it!")
        #expect(StatsView.streakHint(PlayerStats(currentStreak: 4, streakAtRisk: false)) == nil)
        #expect(StatsView.streakHint(PlayerStats(currentStreak: 0, streakAtRisk: true)) == nil)
    }

    @Test func testShowsNudge() {
        #expect(StatsView.showsNudge(.empty))
        #expect(!StatsView.showsNudge(PlayerStats(gamesPlayed: 1)))
    }

    @Test func testBestRank() {
        #expect(StatsView.bestRankText(nil) == "—")
        #expect(StatsView.bestRankText(.legend) == "Legend")
        #expect(StatsView.showsGlow(.mythicGrandmaster))
        #expect(!StatsView.showsGlow(.legend))
        #expect(!StatsView.showsGlow(nil))
    }

    @Test func testTileAccessibilityLabel() {
        #expect(StatsView.tileAccessibilityLabel(caption: "Best score", value: 142) == "Best score, 142")
        #expect(StatsView.tileAccessibilityLabel(caption: "Average score", value: nil) == "Average score, not available")
        #expect(StatsView.tileAccessibilityLabel(caption: "Words found", value: 12, sectionPrefix: "Today") == "Today, Words found, 12")
    }

    @Test func testHeroAccessibilityLabel() {
        #expect(StatsView.heroAccessibilityLabel(PlayerStats(currentStreak: 4, longestStreak: 12))
                == "Current streak 4 days. Longest streak 12 days.")
        #expect(StatsView.heroAccessibilityLabel(PlayerStats(currentStreak: 1, longestStreak: 1))
                == "Current streak 1 day. Longest streak 1 day.")
        #expect(StatsView.heroAccessibilityLabel(PlayerStats(currentStreak: 4, longestStreak: 12, streakAtRisk: true))
                == "Current streak 4 days. Longest streak 12 days. Play today to keep it!")
        #expect(StatsView.heroAccessibilityLabel(PlayerStats()) == "Start a streak today!")
        #expect(StatsView.heroAccessibilityLabel(PlayerStats(currentStreak: 0, longestStreak: 5))
                == "Start a streak today! Longest streak 5 days.")
    }

    @Test func testGridColumnCount() {
        #expect(StatsView.gridColumnCount(isAccessibilitySize: false) == 2)
        #expect(StatsView.gridColumnCount(isAccessibilitySize: true) == 1)
    }

    @Test func testOverflowGlow() {
        #expect(OverflowGlow.lerp(0.0...10.0, 0.5) == 5.0)
        #expect(OverflowGlow.pulse(time: 123, reduceMotion: true) == 0.5)
        #expect(OverflowGlow.pulse(time: 0, reduceMotion: false) == 0.5)
        #expect(abs(OverflowGlow.pulse(time: 0.4, reduceMotion: false) - 1.0) < 1e-9)
    }

    @Test func testPlayerStatsEmpty() {
        let e = PlayerStats.empty
        #expect(e.puzzlesToday == 0 && e.todayScore == 0 && e.todayWords == 0)
        #expect(e.currentStreak == 0 && e.longestStreak == 0 && !e.streakAtRisk)
        #expect(e.gamesPlayed == 0 && e.bestScore == 0 && e.totalWords == 0)
        #expect(e.pangrams == 0 && e.sweeps == 0)
        #expect(e.averageScore == nil && e.averageWords == nil && e.bestRank == nil)
    }
}

struct StatsCountUpTimingTests {
    @Test func smallNumbersAreLinear() {
        #expect(abs(GameTheme.statsCountUpSeconds(for: 45) - 0.45) < 0.0001)
        #expect(abs(GameTheme.statsCountUpSeconds(for: 100) - 1.0) < 0.0001)
        #expect(GameTheme.statsCountUpSeconds(for: 0) == 0)
    }

    @Test func bigNumbersGrowSublinearlyButStillLonger() {
        let t760 = GameTheme.statsCountUpSeconds(for: 760)
        let t1169 = GameTheme.statsCountUpSeconds(for: 1169)
        #expect(t760 > 1.0 && t760 < 7.6)
        #expect(t1169 > t760 && t1169 < 4.0)
    }
}
