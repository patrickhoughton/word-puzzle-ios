import Testing
import Foundation
import SwiftData
@testable import WordPuzzle

@MainActor
@Suite struct PersistenceStatsTests {

    private func makeStore(calendar: Calendar = .current) throws -> PersistenceStore {
        PersistenceStore(container: try PersistenceStore.makeContainer(inMemory: true), calendar: calendar)
    }

    private var cal: Calendar { .current }
    private func day(_ offset: Int, hour: Int = 12, minute: Int = 0, from base: Date) -> Date {
        let start = cal.startOfDay(for: base)
        let d = cal.date(byAdding: .day, value: offset, to: start)!
        return cal.date(bySettingHour: hour, minute: minute, second: 0, of: d)!
    }

    // MARK: longestStreak

    @Test func longestStreakEmptyIsZero() throws {
        #expect(try makeStore().longestStreak() == 0)
    }

    @Test func longestStreakFindsBestRun() throws {
        let store = try makeStore()
        let base = Date()
        for o in [0, 1, 2, 5, 6] { store.record(score: 1, wordsFoundCount: 1, date: day(o - 20, from: base)) }
        #expect(store.longestStreak() == 3)
    }

    @Test func longestStreakSameDayCountsOnce() throws {
        let store = try makeStore()
        let base = Date()
        for h in [9, 12, 15] { store.record(score: 1, wordsFoundCount: 1, date: day(-3, hour: h, from: base)) }
        #expect(store.longestStreak() == 1)
    }

    @Test func longestStreakAcrossMidnight() throws {
        let store = try makeStore()
        let base = Date()
        store.record(score: 1, wordsFoundCount: 1, date: day(-5, hour: 23, minute: 59, from: base))
        store.record(score: 1, wordsFoundCount: 1, date: day(-4, hour: 0, minute: 1, from: base))
        #expect(store.longestStreak() == 2)
    }

    @Test func longestStreakDSTSafe() throws {
        var ny = Calendar(identifier: .gregorian)
        ny.timeZone = TimeZone(identifier: "America/New_York")!
        func noon(_ y: Int, _ m: Int, _ d: Int) -> Date {
            ny.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
        }
        let spring = try makeStore(calendar: ny)
        for d in [7, 8, 9] { spring.record(score: 1, wordsFoundCount: 1, date: noon(2026, 3, d)) }
        #expect(spring.longestStreak() == 3)

        let fall = try makeStore(calendar: ny)
        fall.record(score: 1, wordsFoundCount: 1, date: noon(2026, 10, 31))
        fall.record(score: 1, wordsFoundCount: 1, date: noon(2026, 11, 1))
        fall.record(score: 1, wordsFoundCount: 1, date: noon(2026, 11, 2))
        #expect(fall.longestStreak() == 3)
    }

    // MARK: averages

    @Test func averageScoreRounding() throws {
        let store = try makeStore()
        #expect(store.averageScore() == nil)
        store.record(score: 10, wordsFoundCount: 1)
        store.record(score: 11, wordsFoundCount: 1)
        #expect(store.averageScore() == 11)
        let s2 = try makeStore()
        for sc in [10, 10, 11] { s2.record(score: sc, wordsFoundCount: 1) }
        #expect(s2.averageScore() == 10)
    }

    @Test func averageWordsRounding() throws {
        let store = try makeStore()
        #expect(store.averageWordsPerGame() == nil)
        store.record(score: 1, wordsFoundCount: 4)
        store.record(score: 1, wordsFoundCount: 5)
        #expect(store.averageWordsPerGame() == 5)
        let s2 = try makeStore()
        for w in [3, 4, 4] { s2.record(score: 1, wordsFoundCount: w) }
        #expect(s2.averageWordsPerGame() == 4)
    }

    // MARK: rank / pangrams / sweeps

    @Test func bestRankIgnoresNilAndPicksHighest() throws {
        let store = try makeStore()
        #expect(store.bestRank() == nil)
        store.record(score: 1, wordsFoundCount: 1)
        #expect(store.bestRank() == nil)
        store.record(score: 1, wordsFoundCount: 1, rank: .adept)
        store.record(score: 1, wordsFoundCount: 1, rank: .legend)
        store.record(score: 1, wordsFoundCount: 1, rank: .expert)
        #expect(store.bestRank() == .legend)
        store.record(score: 1, wordsFoundCount: 1, rank: .mythicGrandmaster)
        #expect(store.bestRank() == .mythicGrandmaster)
    }

    @Test func pangramAndSweepTotals() throws {
        let store = try makeStore()
        #expect(store.totalPangramsFound() == 0)
        #expect(store.totalSweeps() == 0)
        store.record(score: 1, wordsFoundCount: 1, pangramsFound: 2, hadSweep: true)
        store.record(score: 1, wordsFoundCount: 1)
        store.record(score: 1, wordsFoundCount: 1, pangramsFound: 1, hadSweep: false)
        store.record(score: 1, wordsFoundCount: 1, pangramsFound: 0, hadSweep: true)
        #expect(store.totalPangramsFound() == 3)
        #expect(store.totalSweeps() == 2)
    }

    @Test func hasFinishedRoundToday() throws {
        let now = Date()
        let a = try makeStore()
        a.recordRoundStarted(date: now)
        #expect(a.hasFinishedRoundToday(now: now) == false)
        let b = try makeStore()
        b.record(score: 1, wordsFoundCount: 1, date: day(-1, from: now))
        #expect(b.hasFinishedRoundToday(now: now) == false)
        b.record(score: 1, wordsFoundCount: 1, date: now)
        #expect(b.hasFinishedRoundToday(now: now) == true)
    }

    // MARK: playerStats

    @Test func playerStatsEmpty() throws {
        #expect(try makeStore().playerStats() == PlayerStats.empty)
    }

    @Test func playerStatsFull() throws {
        let store = try makeStore()
        let now = day(0, hour: 14, from: Date())
        store.recordRoundStarted(date: day(0, hour: 9, from: now))
        store.recordRoundStarted(date: day(0, hour: 10, from: now))
        store.record(score: 40, wordsFoundCount: 12, date: day(-1, from: now), rank: .expert, pangramsFound: 1, hadSweep: false)
        store.record(score: 61, wordsFoundCount: 20, date: day(0, from: now), rank: .legend, pangramsFound: 2, hadSweep: true)
        let s = store.playerStats(now: now)
        #expect(s == PlayerStats(
            puzzlesToday: 2, todayScore: 61, todayWords: 20,
            currentStreak: 2, longestStreak: 2, streakAtRisk: false,
            gamesPlayed: 2, bestScore: 61, totalWords: 32,
            averageScore: 51, averageWords: 16, bestRank: .legend,
            pangrams: 3, sweeps: 1))
    }

    @Test func playerStatsAtRisk() throws {
        let store = try makeStore()
        let now = day(0, hour: 14, from: Date())
        store.record(score: 1, wordsFoundCount: 1, date: day(-1, from: now))
        store.record(score: 1, wordsFoundCount: 1, date: day(-2, from: now))
        let s = store.playerStats(now: now)
        #expect(s.currentStreak == 2)
        #expect(s.streakAtRisk == true)
    }

    @Test func playerStatsBrokenStreakKeepsLongest() throws {
        let store = try makeStore()
        let now = day(0, hour: 14, from: Date())
        for o in [-6, -5, -4, -3] { store.record(score: 1, wordsFoundCount: 1, date: day(o, from: now)) }
        let s = store.playerStats(now: now)
        #expect(s.currentStreak == 0)
        #expect(s.longestStreak == 4)
        #expect(s.streakAtRisk == false)
    }
}
