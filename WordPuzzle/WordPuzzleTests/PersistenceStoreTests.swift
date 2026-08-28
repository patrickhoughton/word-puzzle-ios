import Testing
import Foundation
import SwiftData
@testable import WordPuzzle

@MainActor
@Suite struct PersistenceStoreTests {

    private func makeInMemoryStore() throws -> PersistenceStore {
        let container = try PersistenceStore.makeContainer(inMemory: true)
        return PersistenceStore(container: container)
    }

    @Test func testPuzzlesPlayedTodayCountsTodaysSessions() throws {
        let store = try makeInMemoryStore()
        #expect(store.puzzlesPlayedToday() == 0)
        store.record(score: 10, wordsFoundCount: 4)
        store.record(score: 22, wordsFoundCount: 9)
        store.record(score: 5, wordsFoundCount: 3)
        #expect(store.puzzlesPlayedToday() == 3)
    }

    @Test func testPuzzlesPlayedTodayExcludesEarlierDays() throws {
        let store = try makeInMemoryStore()
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let lateYesterday = calendar.date(byAdding: .minute, value: -1, to: startOfToday)!
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: now)!

        store.record(score: 40, wordsFoundCount: 15, date: lateYesterday)
        store.record(score: 33, wordsFoundCount: 12, date: threeDaysAgo)
        store.record(score: 10, wordsFoundCount: 4, date: now)
        store.record(score: 12, wordsFoundCount: 5, date: now)

        #expect(store.puzzlesPlayedToday(now: now) == 2)
    }

    @Test func testPuzzlesPlayedTodayPersistsAcrossRestart() throws {
        // ROADMAP SC-1: "persists across app restarts". An in-memory container cannot
        // prove this, so use a real on-disk SQLite store at a temp URL, drop the
        // container, then reopen the SAME file — that is a genuine cold start.
        let storeURL = URL.temporaryDirectory
            .appending(path: "PersistenceStoreTests-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: storeURL) }

        do {
            let container = try PersistenceStore.makeContainer(url: storeURL)
            let store = PersistenceStore(container: container)
            store.record(score: 10, wordsFoundCount: 4)
            store.record(score: 20, wordsFoundCount: 8)
            #expect(store.puzzlesPlayedToday() == 2)
        } // container released here — simulates app termination

        let reopenedContainer = try PersistenceStore.makeContainer(url: storeURL)
        let reopenedStore = PersistenceStore(container: reopenedContainer)
        #expect(reopenedStore.puzzlesPlayedToday() == 2)
        #expect(reopenedStore.totalGamesPlayed() == 2)
    }

    @Test func testLifetimeStatsAccumulate() throws {
        let store = try makeInMemoryStore()

        #expect(store.totalGamesPlayed() == 0)
        #expect(store.bestScore() == 0)
        #expect(store.totalWordsFound() == 0)

        let calendar = Calendar.current
        let now = Date()
        store.record(score: 14, wordsFoundCount: 4, date: calendar.date(byAdding: .day, value: -5, to: now)!)
        store.record(score: 57, wordsFoundCount: 12, date: calendar.date(byAdding: .day, value: -2, to: now)!)
        store.record(score: 33, wordsFoundCount: 9, date: now)

        #expect(store.totalGamesPlayed() == 3)
        #expect(store.bestScore() == 57)
        #expect(store.totalWordsFound() == 25)

        // A later, lower-scoring session must not lower the best score.
        store.record(score: 12, wordsFoundCount: 5, date: now)
        #expect(store.totalGamesPlayed() == 4)
        #expect(store.bestScore() == 57)
        #expect(store.totalWordsFound() == 30)
    }

    // MARK: - RET-01 streak

    /// Helper: a date N days before `now`, at midday to stay clear of day boundaries.
    private func daysAgo(_ n: Int, from now: Date = Date()) -> Date {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        let shifted = calendar.date(byAdding: .day, value: -n, to: startOfDay)!
        return calendar.date(byAdding: .hour, value: 12, to: shifted)!
    }

    @Test func testStreakIsZeroForEmptyStore() throws {
        let store = try makeInMemoryStore()
        #expect(store.currentStreak() == 0)
    }

    @Test func testStreakIncrementsOnConsecutiveDays() throws {
        let store = try makeInMemoryStore()
        let now = Date()

        store.record(score: 10, wordsFoundCount: 4, date: daysAgo(0, from: now))
        #expect(store.currentStreak(now: now) == 1)

        store.record(score: 12, wordsFoundCount: 5, date: daysAgo(1, from: now))
        #expect(store.currentStreak(now: now) == 2)

        store.record(score: 14, wordsFoundCount: 6, date: daysAgo(2, from: now))
        #expect(store.currentStreak(now: now) == 3)

        // Multiple sessions on the same day still count as one day.
        store.record(score: 9, wordsFoundCount: 3, date: daysAgo(0, from: now))
        store.record(score: 8, wordsFoundCount: 3, date: daysAgo(0, from: now))
        #expect(store.currentStreak(now: now) == 3)
    }

    @Test func testStreakResetsAfterMissedDay() throws {
        let store = try makeInMemoryStore()
        let now = Date()

        // Played today, yesterday, and 3 days ago — day -2 was missed.
        store.record(score: 10, wordsFoundCount: 4, date: daysAgo(0, from: now))
        store.record(score: 11, wordsFoundCount: 4, date: daysAgo(1, from: now))
        store.record(score: 12, wordsFoundCount: 5, date: daysAgo(3, from: now))
        #expect(store.currentStreak(now: now) == 2)

        // A history that stops 2 days ago is a broken streak.
        let brokenStore = try makeInMemoryStore()
        brokenStore.record(score: 10, wordsFoundCount: 4, date: daysAgo(2, from: now))
        brokenStore.record(score: 10, wordsFoundCount: 4, date: daysAgo(3, from: now))
        #expect(brokenStore.currentStreak(now: now) == 0)

        // After a long gap, the next play starts a fresh streak of 1.
        let restartStore = try makeInMemoryStore()
        restartStore.record(score: 10, wordsFoundCount: 4, date: daysAgo(5, from: now))
        restartStore.record(score: 10, wordsFoundCount: 4, date: daysAgo(0, from: now))
        #expect(restartStore.currentStreak(now: now) == 1)
    }

    @Test func testStreakSurvivesGraceDayBeforePlayingToday() throws {
        let store = try makeInMemoryStore()
        let now = Date()
        // Played yesterday and the day before, nothing yet today.
        store.record(score: 10, wordsFoundCount: 4, date: daysAgo(1, from: now))
        store.record(score: 10, wordsFoundCount: 4, date: daysAgo(2, from: now))
        #expect(store.currentStreak(now: now) == 2)
    }
}
