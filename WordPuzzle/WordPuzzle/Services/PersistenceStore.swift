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

    // MARK: - Lifetime stats (RET-02)

    /// COUNT — pushed down to SQLite, does not instantiate any GameRecord objects.
    func totalGamesPlayed() -> Int {
        (try? context.fetchCount(FetchDescriptor<GameRecord>())) ?? 0
    }

    /// MAX — expressed as ORDER BY score DESC LIMIT 1, which SwiftData does push down.
    func bestScore() -> Int {
        var descriptor = FetchDescriptor<GameRecord>(
            sortBy: [SortDescriptor(\.score, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first?.score ?? 0
    }

    /// SUM — RESEARCH Pitfall 3: SwiftData has NO SUM/AVG pushdown (unlike Core Data's
    /// NSExpressionDescription). Do not attempt an expression macro or a map/reduce inside
    /// the #Predicate macro — it will not compile. Fetch and reduce in Swift instead; at
    /// this app's data scale (a few sessions per day, personal history) the cost is negligible.
    func totalWordsFound() -> Int {
        let records = (try? context.fetch(FetchDescriptor<GameRecord>())) ?? []
        return records.reduce(0) { $0 + $1.wordsFoundCount }
    }

    // MARK: - Daily streak (RET-01)

    /// Number of consecutive local days, ending today or yesterday, on which at least
    /// one session was recorded.
    ///
    /// Derived from GameRecord dates rather than stored as a counter — a stored counter
    /// is a second source of truth that drifts out of sync with actual play history
    /// (RESEARCH anti-pattern). Bounded to a 400-day window so the query cost is capped
    /// regardless of history size; a streak longer than 400 days is not a realistic case
    /// for this app and would simply report 400.
    func currentStreak(now: Date = .now) -> Int {
        let today = calendar.startOfDay(for: now)
        guard let windowStart = calendar.date(byAdding: .day, value: -400, to: today) else {
            return 0
        }

        let descriptor = FetchDescriptor<GameRecord>(
            predicate: #Predicate { $0.date >= windowStart }
        )
        let records = (try? context.fetch(descriptor)) ?? []
        guard !records.isEmpty else { return 0 }

        // Collapse many sessions per day down to distinct days.
        let playedDays = Set(records.map { calendar.startOfDay(for: $0.date) })

        // Anchor the walk: today if played today, otherwise yesterday (grace day).
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
            return 0
        }
        var cursor: Date
        if playedDays.contains(today) {
            cursor = today
        } else if playedDays.contains(yesterday) {
            cursor = yesterday
        } else {
            return 0  // most recent play was 2+ days ago — streak broken
        }

        var streak = 0
        while playedDays.contains(cursor) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previousDay
        }
        return streak
    }
}
