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
        return try ModelContainer(for: GameRecord.self, RoundStartRecord.self, configurations: configuration)
    }

    // MARK: - Writing

    /// Records one finished session and saves immediately so the value survives
    /// an app termination that happens before the next autosave.
    /// Phase 9 D-15: rank/pangramsFound/hadSweep are defaulted so the frozen Phase 2 call sites compile unchanged.
    @discardableResult
    func record(score: Int, wordsFoundCount: Int, date: Date = .now,
                rank: RankTier? = nil, pangramsFound: Int? = nil, hadSweep: Bool? = nil) -> GameRecord {
        let entry = GameRecord(date: date, score: score, wordsFoundCount: wordsFoundCount,
                               rankRaw: rank?.rawValue, pangramsFound: pangramsFound, hadSweep: hadSweep)
        context.insert(entry)
        try? context.save()
        return entry
    }

    /// D-02: called once per round that actually STARTS (GameViewModel.startNewRound(with:)).
    /// This — not `record(...)` — is what the daily free-puzzle limit counts, so a round
    /// abandoned before "Finish Round" still consumes one of the day's three free puzzles.
    @discardableResult
    func recordRoundStarted(date: Date = .now) -> RoundStartRecord {
        let entry = RoundStartRecord(date: date)
        context.insert(entry)
        try? context.save()
        return entry
    }

    // MARK: - Daily count

    /// Number of rounds STARTED during the current LOCAL calendar day (D-02) — this is
    /// the free-tier daily limit counter. CHANGED in Phase 4: previously counted
    /// GameRecord (finished rounds); now counts RoundStartRecord so an abandoned round
    /// still consumes a free puzzle. Signature and day boundary are unchanged.
    /// Uses fetchCount so SQLite does the COUNT — never fetch(...).count here.
    func puzzlesPlayedToday(now: Date = .now) -> Int {
        let (startOfDay, startOfNextDay) = todayBounds(now: now)
        let descriptor = FetchDescriptor<RoundStartRecord>(
            predicate: #Predicate { $0.date >= startOfDay && $0.date < startOfNextDay }
        )
        return (try? context.fetchCount(descriptor)) ?? 0
    }

    // MARK: - Today's totals (D-07)

    /// D-07: sum of score across today's FINISHED rounds only (GameRecord, not
    /// RoundStartRecord) — an abandoned round contributes 0, per D-02's constraint that
    /// abandoned rounds must not contribute a score.
    /// SUM is done in Swift: SwiftData has NO SUM pushdown (same reasoning as totalWordsFound()).
    func todayTotalScore(now: Date = .now) -> Int {
        let (startOfDay, startOfNextDay) = todayBounds(now: now)
        let descriptor = FetchDescriptor<GameRecord>(
            predicate: #Predicate { $0.date >= startOfDay && $0.date < startOfNextDay }
        )
        let records = (try? context.fetch(descriptor)) ?? []
        return records.reduce(0) { $0 + $1.score }
    }

    /// D-07: sum of words found across today's FINISHED rounds only. See todayTotalScore().
    func todayTotalWordsFound(now: Date = .now) -> Int {
        let (startOfDay, startOfNextDay) = todayBounds(now: now)
        let descriptor = FetchDescriptor<GameRecord>(
            predicate: #Predicate { $0.date >= startOfDay && $0.date < startOfNextDay }
        )
        let records = (try? context.fetch(descriptor)) ?? []
        return records.reduce(0) { $0 + $1.wordsFoundCount }
    }

    /// D-06 / RESEARCH Pitfall 4: the single source of truth for "when do free puzzles
    /// reset". The paywall countdown MUST use this rather than duplicating calendar math
    /// or using a rolling 24-hour offset — a rolling offset diverges from this boundary
    /// across DST transitions and over the course of a session.
    func nextResetDate(now: Date = .now) -> Date {
        todayBounds(now: now).1
    }

    /// Local-calendar-day half-open interval [startOfDay, startOfNextDay).
    /// Extracted because puzzlesPlayedToday / todayTotalScore / todayTotalWordsFound /
    /// nextResetDate all need the identical boundary.
    private func todayBounds(now: Date) -> (Date, Date) {
        let startOfDay = calendar.startOfDay(for: now)
        let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        return (startOfDay, startOfNextDay)
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

    // MARK: - Phase 9 stats (D-07, D-09, D-10, D-14, D-21)

    /// D-07: longest run of consecutive LOCAL calendar days with >= 1 finished round, over FULL
    /// history (no 400-day window). Adjacency via date(byAdding: .day) so DST days count as one day.
    func longestStreak() -> Int {
        let records = (try? context.fetch(FetchDescriptor<GameRecord>())) ?? []
        let days = Set(records.map { calendar.startOfDay(for: $0.date) }).sorted()
        var best = 0, run = 0
        var previous: Date?
        for day in days {
            if let previous, calendar.date(byAdding: .day, value: 1, to: previous) == day { run += 1 } else { run = 1 }
            best = max(best, run)
            previous = day
        }
        return best
    }

    /// D-09/D-23: whole number, rounded to nearest; nil when no finished games (D-20).
    func averageScore() -> Int? {
        let records = (try? context.fetch(FetchDescriptor<GameRecord>())) ?? []
        guard !records.isEmpty else { return nil }
        return Int((Double(records.reduce(0) { $0 + $1.score }) / Double(records.count)).rounded())
    }

    func averageWordsPerGame() -> Int? {
        let records = (try? context.fetch(FetchDescriptor<GameRecord>())) ?? []
        guard !records.isEmpty else { return nil }
        return Int((Double(records.reduce(0) { $0 + $1.wordsFoundCount }) / Double(records.count)).rounded())
    }

    /// D-14: highest stored tier; pre-Phase-9 rows (nil) are ignored (D-12).
    func bestRank() -> RankTier? {
        let records = (try? context.fetch(FetchDescriptor<GameRecord>())) ?? []
        return records.compactMap(\.rankRaw).max().flatMap(RankTier.init(rawValue:))
    }

    /// D-10/D-13: finished rounds only; nil (pre-Phase-9) contributes 0.
    func totalPangramsFound() -> Int {
        let records = (try? context.fetch(FetchDescriptor<GameRecord>())) ?? []
        return records.reduce(0) { $0 + ($1.pangramsFound ?? 0) }
    }

    /// D-10: number of finished rounds whose pangram sweep fired.
    func totalSweeps() -> Int {
        let records = (try? context.fetch(FetchDescriptor<GameRecord>())) ?? []
        return records.filter { $0.hadSweep == true }.count
    }

    /// D-21: true when a round was FINISHED today (GameRecord, not RoundStartRecord).
    func hasFinishedRoundToday(now: Date = .now) -> Bool {
        let (startOfDay, startOfNextDay) = todayBounds(now: now)
        let descriptor = FetchDescriptor<GameRecord>(
            predicate: #Predicate { $0.date >= startOfDay && $0.date < startOfNextDay }
        )
        return ((try? context.fetchCount(descriptor)) ?? 0) > 0
    }

    /// Phase 9: the single snapshot builder GameView calls each time a stats surface opens
    /// (RESEARCH Pitfall 4: never a cached snapshot).
    func playerStats(now: Date = .now) -> PlayerStats {
        let current = currentStreak(now: now)
        return PlayerStats(
            puzzlesToday: puzzlesPlayedToday(now: now),
            todayScore: todayTotalScore(now: now),
            todayWords: todayTotalWordsFound(now: now),
            currentStreak: current,
            // Pitfall 5: currentStreak is 400-day-windowed, longestStreak is full history;
            // max() guarantees longest >= current for any edge case.
            longestStreak: max(longestStreak(), current),
            streakAtRisk: current > 0 && !hasFinishedRoundToday(now: now),
            gamesPlayed: totalGamesPlayed(),
            bestScore: bestScore(),
            totalWords: totalWordsFound(),
            averageScore: averageScore(),
            averageWords: averageWordsPerGame(),
            bestRank: bestRank(),
            pangrams: totalPangramsFound(),
            sweeps: totalSweeps()
        )
    }
}
