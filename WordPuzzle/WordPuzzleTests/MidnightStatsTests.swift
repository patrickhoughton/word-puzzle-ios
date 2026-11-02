import Testing
import Foundation
import SwiftData
@testable import WordPuzzle

/// A round started on day N and still in progress on day N+1 must show split-by-day stats.
@MainActor
@Suite struct MidnightStatsTests {
    private let cal = Calendar.current

    private func makeStore() throws -> PersistenceStore {
        PersistenceStore(container: try PersistenceStore.makeContainer(inMemory: true), calendar: cal)
    }

    /// 22:00 yesterday and 09:00 today, relative to a fixed "now" at 12:00 today.
    private var times: (yesterday: Date, today: Date, now: Date) {
        let start = cal.startOfDay(for: Date())
        let y = cal.date(byAdding: .hour, value: -2, to: start)!
        return (y, cal.date(byAdding: .hour, value: 9, to: start)!, cal.date(byAdding: .hour, value: 12, to: start)!)
    }

    @Test func inProgressRoundSplitsWordsAndScoreByDay() throws {
        let store = try makeStore()
        let t = times
        store.recordRoundStarted(date: t.yesterday)
        store.recordWordFound(points: 5, date: t.yesterday, roundStartedAt: t.yesterday)
        store.recordWordFound(points: 7, date: t.today, roundStartedAt: t.yesterday)
        store.recordWordFound(points: 3, date: t.today, roundStartedAt: t.yesterday)

        #expect(store.todayTotalScore(now: t.now) == 10)
        #expect(store.todayTotalWordsFound(now: t.now) == 2)
        #expect(store.todayTotalScore(now: t.yesterday) == 5)
        #expect(store.todayTotalWordsFound(now: t.yesterday) == 1)
    }

    @Test func carriedOverRoundCountsAsPuzzleToday() throws {
        let store = try makeStore()
        let t = times
        store.recordRoundStarted(date: t.yesterday)
        // Nothing found yet today, but the active round (started yesterday) is being played.
        #expect(store.puzzlesTouchedToday(now: t.now) == 0)
        #expect(store.playerStats(now: t.now, activeRoundStartedAt: t.yesterday).puzzlesToday == 1)
        // After words are found today the carried round is counted even once no longer active.
        store.recordWordFound(points: 4, date: t.today, roundStartedAt: t.yesterday)
        store.recordWordFound(points: 4, date: t.today, roundStartedAt: t.yesterday)
        #expect(store.puzzlesTouchedToday(now: t.now) == 1)
        // The free-tier limit counter is unchanged: only today's STARTS.
        #expect(store.puzzlesPlayedToday(now: t.now) == 0)
        // Active carried round + a round started today.
        store.recordRoundStarted(date: t.today)
        #expect(store.puzzlesTouchedToday(now: t.now, activeRoundStartedAt: t.yesterday) == 2)
    }

    @Test func legacyFinishedRecordsTodayStillCountBeforeFirstWordEvent() throws {
        let store = try makeStore()
        let t = times
        store.record(score: 30, wordsFoundCount: 10, date: t.today)          // pre-upgrade finished round
        store.recordWordFound(points: 6, date: t.now, roundStartedAt: t.now)  // first event after upgrade
        #expect(store.todayTotalScore(now: t.now) == 36)
        #expect(store.todayTotalWordsFound(now: t.now) == 11)
    }

    @Test func viewModelLogsWordsAtTimeFoundAndSnapshotKeepsStart() async throws {
        let wordList = WordList()
        await wordList.load()
        let name = "MidnightStatsTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let persistence = try makeStore()
        let roundStore = RoundSnapshotStore(defaults: defaults)
        let vm = GameViewModel(wordList: wordList, persistenceStore: persistence, roundStore: roundStore)
        vm.startNewRound(with: Puzzle(letters: Set("abcdein"), centerLetter: "a",
                                      validWords: ["bead", "cabin", "dance", "cabined", "abidance"],
                                      pangrams: ["cabined", "abidance"]))
        for ch in "cabin" { vm.append(ch) }
        vm.submitCurrentWord()
        #expect(persistence.todayTotalWordsFound() == 1)
        #expect(persistence.todayTotalScore() == vm.score)
        #expect(persistence.playerStats(activeRoundStartedAt: vm.roundStartedAt).puzzlesToday == 1)

        // Relaunch on a later day: the restored round keeps its original start (yesterday).
        let yesterday = cal.date(byAdding: .day, value: -1, to: Date())!
        var snap = try #require(roundStore.load())
        snap.startedAt = yesterday
        roundStore.save(snap)
        let vm2 = GameViewModel(wordList: wordList, persistenceStore: persistence, roundStore: roundStore)
        #expect(vm2.restoreSavedRound())
        #expect(vm2.roundStartedAt == yesterday)
        // Replay on restore must NOT double-log words.
        #expect(persistence.todayTotalWordsFound() == 1)
    }
}
