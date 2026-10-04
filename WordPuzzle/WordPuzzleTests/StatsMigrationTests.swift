import Testing
import Foundation
import SwiftData
@testable import WordPuzzle

/// Frozen copy of the pre-Phase-9 on-disk schema (GameRecord + RoundStartRecord at commit 5b8ea70).
/// NEVER edit these nested models: they stand in for the store already on players' devices.
/// Entity names derive from the unqualified class name, so these map onto the same
/// SQLite tables (ZGAMERECORD / ZROUNDSTARTRECORD) as the production models.
enum LegacySchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
    static var models: [any PersistentModel.Type] { [GameRecord.self, RoundStartRecord.self] }

    @Model final class GameRecord {
        var date: Date
        var score: Int
        var wordsFoundCount: Int
        init(date: Date, score: Int, wordsFoundCount: Int) {
            self.date = date; self.score = score; self.wordsFoundCount = wordsFoundCount
        }
    }

    @Model final class RoundStartRecord {
        var date: Date
        init(date: Date) { self.date = date }
    }
}

@MainActor
@Suite struct StatsMigrationTests {
    /// Writes a legacy-schema store at `url` and fully releases its container before returning.
    private func writeLegacyStore(at url: URL, day: Date) throws {
        let legacy = try ModelContainer(
            for: Schema(versionedSchema: LegacySchemaV1.self),
            configurations: ModelConfiguration(url: url)
        )
        let context = legacy.mainContext
        context.insert(LegacySchemaV1.GameRecord(date: day, score: 40, wordsFoundCount: 12))
        context.insert(LegacySchemaV1.GameRecord(date: day.addingTimeInterval(-86_400), score: 25, wordsFoundCount: 9))
        context.insert(LegacySchemaV1.GameRecord(date: day.addingTimeInterval(-172_800), score: 61, wordsFoundCount: 20))
        context.insert(LegacySchemaV1.RoundStartRecord(date: day))
        try context.save()
    }

    private func tempStoreURL() -> URL {
        URL.temporaryDirectory.appending(path: "StatsMigrationTests-\(UUID().uuidString).store")
    }

    private func removeStore(at url: URL) {
        for suffix in ["", "-wal", "-shm"] {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + suffix))
        }
    }

    @Test func testLegacyStoreOpensUnderCurrentSchemaWithoutDataLoss() throws {
        let url = tempStoreURL()
        defer { removeStore(at: url) }
        let day = Date(timeIntervalSince1970: 1_790_000_000)
        try writeLegacyStore(at: url, day: day)

        let container = try PersistenceStore.makeContainer(url: url)
        let store = PersistenceStore(container: container)
        #expect(store.totalGamesPlayed() == 3)
        #expect(store.bestScore() == 61)
        #expect(store.totalWordsFound() == 41)

        let records = try container.mainContext.fetch(FetchDescriptor<GameRecord>())
        #expect(records.count == 3)
        #expect(records.allSatisfy { $0.rankRaw == nil && $0.pangramsFound == nil && $0.hadSweep == nil })

        store.record(score: 99, wordsFoundCount: 30, date: day, rank: .legend, pangramsFound: 2, hadSweep: true)
        #expect(store.totalGamesPlayed() == 4)
        #expect(store.bestScore() == 99)
        let all = try container.mainContext.fetch(FetchDescriptor<GameRecord>())
        let row = try #require(all.first { $0.score == 99 })
        #expect(row.rankRaw == RankTier.legend.rawValue)
        #expect(row.pangramsFound == 2)
        #expect(row.hadSweep == true)
    }

    @Test func testMigratedStoreStaysReadableAcrossReopen() throws {
        let url = tempStoreURL()
        defer { removeStore(at: url) }
        let day = Date(timeIntervalSince1970: 1_790_000_000)
        try writeLegacyStore(at: url, day: day)

        do {
            let container = try PersistenceStore.makeContainer(url: url)
            let store = PersistenceStore(container: container)
            store.record(score: 99, wordsFoundCount: 30, date: day, rank: .legend, pangramsFound: 2, hadSweep: true)
            #expect(store.totalGamesPlayed() == 4)
        }
        let reopened = try PersistenceStore.makeContainer(url: url)
        #expect(PersistenceStore(container: reopened).totalGamesPlayed() == 4)
    }

    @Test func testRecordWithoutNewFieldsLeavesThemNil() throws {
        let container = try PersistenceStore.makeContainer(inMemory: true)
        let store = PersistenceStore(container: container)
        store.record(score: 10, wordsFoundCount: 4)
        let row = try #require(try container.mainContext.fetch(FetchDescriptor<GameRecord>()).first)
        #expect(row.rankRaw == nil && row.pangramsFound == nil && row.hadSweep == nil)
    }

    @Test func testRecordPersistsNewFields() throws {
        let container = try PersistenceStore.makeContainer(inMemory: true)
        let store = PersistenceStore(container: container)
        store.record(score: 50, wordsFoundCount: 10, rank: .mythicGrandmaster, pangramsFound: 0, hadSweep: false)
        let row = try #require(try container.mainContext.fetch(FetchDescriptor<GameRecord>()).first)
        #expect(row.rankRaw == 10)
        #expect(row.pangramsFound == 0)
        #expect(row.hadSweep == false)
    }
}
