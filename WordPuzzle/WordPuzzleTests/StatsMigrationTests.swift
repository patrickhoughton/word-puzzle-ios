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
    }
}
