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
        // totalGamesPlayed() is implemented in Task 2 of this plan; uncommented there.
        // #expect(reopenedStore.totalGamesPlayed() == 2)
    }
}
