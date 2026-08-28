import Foundation
import Observation
import SwiftData

/// CONTEXT D-07: @Observable final class, matching the WordList convention from Phase 1.
/// Injected via .environment() in WordPuzzleApp (plan 02-05).
@Observable
final class PersistenceStore {
    private let container: ModelContainer
    private let calendar: Calendar

    private var context: ModelContext { container.mainContext }

    init(container: ModelContainer, calendar: Calendar = .current) {
        self.container = container
        self.calendar = calendar
    }

    /// Container factory so production (on-disk default) and tests (in-memory or a
    /// temp file URL) request the same schema with different storage.
    /// RESEARCH Pattern 1.
    static func makeContainer(inMemory: Bool = false, url: URL? = nil) throws -> ModelContainer {
        let configuration: ModelConfiguration
        if let url {
            configuration = ModelConfiguration(url: url)
        } else {
            configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        }
        return try ModelContainer(for: GameRecord.self, configurations: configuration)
    }

    // MARK: - Writing

    /// Records one finished session and saves immediately so the value survives
    /// an app termination that happens before the next autosave.
    @discardableResult
    func record(score: Int, wordsFoundCount: Int, date: Date = .now) -> GameRecord {
        let entry = GameRecord(date: date, score: score, wordsFoundCount: wordsFoundCount)
        context.insert(entry)
        try? context.save()
        return entry
    }

    // MARK: - Daily count

    /// Number of sessions recorded during the current LOCAL calendar day.
    /// Uses fetchCount so SQLite does the COUNT — never fetch(...).count here
    /// (RESEARCH anti-pattern: avoids instantiating model objects that go unused).
    func puzzlesPlayedToday(now: Date = .now) -> Int {
        let startOfDay = calendar.startOfDay(for: now)
        guard let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return 0
        }
        let descriptor = FetchDescriptor<GameRecord>(
            predicate: #Predicate { $0.date >= startOfDay && $0.date < startOfNextDay }
        )
        return (try? context.fetchCount(descriptor)) ?? 0
    }
}
