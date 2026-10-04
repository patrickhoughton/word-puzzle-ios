import Testing
import Foundation
import SwiftData
@testable import WordPuzzle

// @Suite(.serialized): the shared WordList loads once sequentially (Phase 1 decision —
// parallel loads cause Simulator memory pressure).
@Suite(.serialized)
@MainActor
final class GameViewModelTests {
    let wordList: WordList

    init() async throws {
        wordList = WordList()
        await wordList.load()
    }

    /// Deterministic puzzle: letters a,c,d,e,l,n,t with center 'a'.
    /// All five words are real ENABLE entries, >= 4 chars, contain 'a', and use only these letters.
    private func fixturePuzzle() -> Puzzle {
        Puzzle(
            letters: Set("acdelnt"),
            centerLetter: "a",
            validWords: ["cane", "lance", "candle", "canted", "dental"],
            pangrams: []
        )
    }

    private func pangramFixturePuzzle() -> Puzzle {
        Puzzle(
            letters: Set("acdelns"),
            centerLetter: "a",
            validWords: ["cane", "clan", "lance", "lanes", "candle", "decals", "scaled", "candles"],
            pangrams: ["candles"]
        )
    }

    /// Phase 8: two pangrams of different lengths, so the sweep fires only on the second.
    /// Lengths: 4 ["bead"], 5 ["cabin","dance"], 7 ["cabined"], 8 ["abidance"].
    private func twoPangramFixturePuzzle() -> Puzzle {
        Puzzle(
            letters: Set("abcdein"),
            centerLetter: "a",
            validWords: ["bead", "cabin", "dance", "cabined", "abidance"],
            pangrams: ["cabined", "abidance"]
        )
    }

    private func submit(_ word: String, on vm: GameViewModel) -> Bool {
        for ch in word { vm.append(ch) }
        return vm.submitCurrentWord()
    }

    // MARK: - Phase 7 foundWordGroups

    @Test func testFoundWordGroupsEmptyBeforeAnyWord() {
        let vm = GameViewModel(wordList: wordList)
        vm.startNewRound(with: pangramFixturePuzzle())
        #expect(vm.foundWordGroups.map(\.length) == [4, 5, 6, 7])
        #expect(vm.foundWordGroups.map(\.total) == [2, 2, 3, 1])
        #expect(vm.foundWordGroups.allSatisfy { $0.found.isEmpty })
        #expect(vm.foundWordGroups.allSatisfy { !$0.isComplete })
    }

    @Test func testFoundWordGroupsIncludeEveryLengthAscending() {
        let vm = GameViewModel(wordList: wordList)
        vm.startNewRound(with: pangramFixturePuzzle())
        #expect(submit("lance", on: vm) == true)
        let groups = vm.foundWordGroups
        #expect(groups.map(\.length) == [4, 5, 6, 7])
        #expect(groups[1].found.map(\.text) == ["lance"])
        #expect(groups[0].found.isEmpty)
        #expect(groups[2].found.isEmpty)
        #expect(groups[3].found.isEmpty)
    }

    @Test func testFoundWordGroupsAlphabetical() {
        let vm = GameViewModel(wordList: wordList)
        vm.startNewRound(with: pangramFixturePuzzle())
        #expect(submit("scaled", on: vm) == true)
        #expect(submit("candle", on: vm) == true)
        #expect(submit("decals", on: vm) == true)
        let group6 = vm.foundWordGroups.first { $0.length == 6 }
        #expect(group6?.found.map(\.text) == ["candle", "decals", "scaled"])
    }

    @Test func testFoundWordGroupsCountsAndCompletion() {
        let vm = GameViewModel(wordList: wordList)
        vm.startNewRound(with: pangramFixturePuzzle())
        #expect(submit("cane", on: vm) == true)
        #expect(submit("clan", on: vm) == true)
        let groups = vm.foundWordGroups
        #expect(groups[0].found.count == 2)
        #expect(groups[0].total == 2)
        #expect(groups[0].isComplete == true)
        #expect(groups[1].isComplete == false)
        #expect(groups[1].found.count == 0)
        #expect(groups[1].total == 2)
    }

    @Test func testFoundWordGroupsPointsAndPangram() {
        let vm = GameViewModel(wordList: wordList)
        vm.startNewRound(with: pangramFixturePuzzle())
        #expect(submit("candles", on: vm) == true)
        #expect(submit("cane", on: vm) == true)
        #expect(submit("lance", on: vm) == true)
        let groups = vm.foundWordGroups
        #expect(groups[3].found == [FoundWord(text: "candles", points: 14, isPangram: true)])
        #expect(groups[0].found == [FoundWord(text: "cane", points: 1, isPangram: false)])
        #expect(groups[1].found == [FoundWord(text: "lance", points: 5, isPangram: false)])
    }

    @Test func testFoundWordGroupsEmptyWithoutPuzzle() {
        let vm = GameViewModel(wordList: wordList)
        #expect(vm.foundWordGroups == [])
    }

    @Test func testAppendAndSubmitBuildsWord() {
        let vm = GameViewModel(wordList: wordList)
        vm.startNewRound(with: fixturePuzzle())
        for ch in "cane" { vm.append(ch) }
        #expect(vm.currentWord == "cane")
        #expect(vm.submitCurrentWord() == true)
        #expect(vm.currentWord.isEmpty)
    }

    @Test func testSubmitInvalidWordReturnsFalse() {
        let vm = GameViewModel(wordList: wordList)
        vm.startNewRound(with: fixturePuzzle())
        #expect(submit("zzzz", on: vm) == false)
        #expect(vm.lastOutcome == .rejected(.missingCenterLetter))
        #expect(vm.rejectedSubmissionCount == 1)
        #expect(vm.score == 0)
        #expect(vm.foundWords.isEmpty)
    }

    @Test func testScoreAndFoundCountUpdateOnCorrectSubmit() {
        let vm = GameViewModel(wordList: wordList)
        vm.startNewRound(with: fixturePuzzle())
        #expect(submit("cane", on: vm) == true)
        // Phase 8 D-14: "cane" is the only 4-letter word, so +4 length bonus.
        #expect(vm.score == 5)
        #expect(vm.foundCount == 1)
        #expect(submit("lance", on: vm) == true)
        // 5 points + 5 length bonus ("lance" is the only 5-letter word).
        #expect(vm.score == 15)
        #expect(vm.foundCount == 2)
    }

    @Test func testMissedWordsGroupedByLength() {
        let vm = GameViewModel(wordList: wordList)
        vm.startNewRound(with: fixturePuzzle())
        #expect(submit("cane", on: vm) == true)
        #expect(vm.missedWordGroups.map(\.length) == [5, 6])
        #expect(vm.missedWordGroups[0].words == ["lance"])
        #expect(vm.missedWordGroups[1].words == ["candle", "canted", "dental"])
    }

    @Test func testShufflePreservesLetterSetExcludesCenter() {
        let vm = GameViewModel(wordList: wordList)
        vm.startNewRound()
        #expect(vm.outerLetters.count == 6)
        #expect(!vm.outerLetters.contains(vm.centerLetter))
        let before = vm.outerLetters
        vm.shuffleOuterLetters()
        #expect(Set(vm.outerLetters) == Set(before))
    }

    @Test func testCorrectSubmissionTogglesHapticTrigger() {
        let vm = GameViewModel(wordList: wordList)
        vm.startNewRound(with: fixturePuzzle())
        #expect(vm.acceptedSubmissionCount == 0)
        #expect(submit("cane", on: vm) == true)
        #expect(vm.acceptedSubmissionCount == 1)
        #expect(submit("lance", on: vm) == true)
        #expect(vm.acceptedSubmissionCount == 2)
    }

    @Test func testDuplicateWordIsRejected() {
        let vm = GameViewModel(wordList: wordList)
        vm.startNewRound(with: fixturePuzzle())
        #expect(submit("cane", on: vm) == true)
        #expect(submit("cane", on: vm) == false)
        // Phase 8 D-14: "cane" is the only 4-letter word, so +4 length bonus.
        #expect(vm.score == 5)
        #expect(vm.foundCount == 1)
    }

    @Test func testDeleteLastAndClear() {
        let vm = GameViewModel(wordList: wordList)
        vm.startNewRound(with: fixturePuzzle())
        vm.append("c")
        vm.append("a")
        vm.append("n")
        vm.deleteLast()
        #expect(vm.currentWord == "ca")
        vm.deleteLast()
        vm.deleteLast()
        vm.deleteLast() // no-op on empty
        #expect(vm.currentWord.isEmpty)
        vm.append("c")
        vm.append("a")
        vm.clearCurrentWord()
        #expect(vm.currentWord.isEmpty)
    }

    @Test func testFinishRoundRecordsSession() throws {
        let container = try PersistenceStore.makeContainer(inMemory: true)
        let store = PersistenceStore(container: container)
        let vm = GameViewModel(wordList: wordList, persistenceStore: store)
        vm.startNewRound(with: fixturePuzzle())
        vm.finishRound()
        #expect(vm.roundPhase == .roundOver)
        #expect(store.totalGamesPlayed() == 1)
    }

    @Test func testStartNewRoundResetsState() {
        let vm = GameViewModel(wordList: wordList)
        vm.startNewRound(with: fixturePuzzle())
        #expect(submit("cane", on: vm) == true)
        vm.startNewRound()
        #expect(vm.score == 0)
        #expect(vm.foundWords.isEmpty)
        #expect(vm.currentWord.isEmpty)
        #expect(vm.roundPhase == .playing)
        #expect(vm.puzzle != nil)
    }

    // MARK: - Phase 4 gate (MON-01 / D-01 / D-02)

    /// D-02: starting a round consumes a free puzzle even if it is never finished.
    /// The daily-limit count and the lifetime "games played" count must not be conflated.
    @Test func testStartNewRoundRecordsRoundStartWithoutRecordingAGame() throws {
        let container = try PersistenceStore.makeContainer(inMemory: true)
        let store = PersistenceStore(container: container)
        let vm = GameViewModel(wordList: wordList, persistenceStore: store)

        vm.startNewRound(with: fixturePuzzle())
        #expect(store.puzzlesPlayedToday() == 1)
        #expect(store.totalGamesPlayed() == 0)

        // Abandoned — no finishRound() — then a second round starts.
        vm.startNewRound(with: fixturePuzzle())
        #expect(store.puzzlesPlayedToday() == 2)
        #expect(store.totalGamesPlayed() == 0)
    }

    /// D-01 branch 1: a free user at the daily limit is paywalled instead of getting a round.
    @Test func testRequestNextRoundPaywallsFreeUserAtDailyLimit() throws {
        let container = try PersistenceStore.makeContainer(inMemory: true)
        let store = PersistenceStore(container: container)
        let vm = GameViewModel(wordList: wordList, persistenceStore: store)

        for _ in 0..<GameViewModel.freePuzzlesPerDay { store.recordRoundStarted() }

        vm.requestNextRound(isPremium: false)
        #expect(vm.roundPhase == .paywalled)
        // No round was started, so the count did not move.
        #expect(store.puzzlesPlayedToday() == GameViewModel.freePuzzlesPerDay)
    }

    /// D-01 branch 2: premium bypasses the limit entirely.
    @Test func testRequestNextRoundAllowsPremiumUserAtDailyLimit() throws {
        let container = try PersistenceStore.makeContainer(inMemory: true)
        let store = PersistenceStore(container: container)
        let vm = GameViewModel(wordList: wordList, persistenceStore: store)

        for _ in 0..<GameViewModel.freePuzzlesPerDay { store.recordRoundStarted() }

        vm.requestNextRound(isPremium: true)
        #expect(vm.roundPhase == .playing)
        #expect(store.puzzlesPlayedToday() == GameViewModel.freePuzzlesPerDay + 1)
    }

    /// MON-01: the 3rd free puzzle must still be playable — the wall is on the 4th.
    @Test func testRequestNextRoundAllowsFreeUserBelowDailyLimit() throws {
        let container = try PersistenceStore.makeContainer(inMemory: true)
        let store = PersistenceStore(container: container)
        let vm = GameViewModel(wordList: wordList, persistenceStore: store)

        store.recordRoundStarted()
        store.recordRoundStarted()

        vm.requestNextRound(isPremium: false)
        #expect(vm.roundPhase == .playing)
        #expect(store.puzzlesPlayedToday() == GameViewModel.freePuzzlesPerDay)
    }

    // MARK: - Phase 6 rejection reasons

    @Test func testRejectTooShort() {
        let vm = GameViewModel(wordList: wordList)
        vm.startNewRound(with: fixturePuzzle())
        #expect(submit("can", on: vm) == false)
        #expect(vm.lastOutcome == .rejected(.tooShort))
    }

    @Test func testRejectPrecedenceTooShortBeforeMissingCenter() {
        let vm = GameViewModel(wordList: wordList)
        vm.startNewRound(with: fixturePuzzle())
        #expect(submit("len", on: vm) == false)
        #expect(vm.lastOutcome == .rejected(.tooShort))
    }

    @Test func testRejectMissingCenterLetter() {
        let vm = GameViewModel(wordList: wordList)
        vm.startNewRound(with: fixturePuzzle())
        #expect(submit("lend", on: vm) == false)
        #expect(vm.lastOutcome == .rejected(.missingCenterLetter))
    }

    @Test func testRejectOutsideLetterIsNotAWord() {
        let vm = GameViewModel(wordList: wordList)
        vm.startNewRound(with: fixturePuzzle())
        #expect(submit("zany", on: vm) == false)
        #expect(vm.lastOutcome == .rejected(.notAWord))
    }

    @Test func testRejectNotInWordList() {
        #expect(wordList.contains("tcaa") == false)
        let vm = GameViewModel(wordList: wordList)
        vm.startNewRound(with: fixturePuzzle())
        #expect(submit("tcaa", on: vm) == false)
        #expect(vm.lastOutcome == .rejected(.notAWord))
    }

    @Test func testRejectAlreadyFoundLeavesStateUnchanged() {
        let vm = GameViewModel(wordList: wordList)
        vm.startNewRound(with: fixturePuzzle())
        #expect(submit("cane", on: vm) == true)
        #expect(submit("cane", on: vm) == false)
        #expect(vm.lastOutcome == .rejected(.alreadyFound))
        // Phase 8 D-14: "cane" is the only 4-letter word, so +4 length bonus.
        #expect(vm.score == 5)
        #expect(vm.foundWords == ["cane"])
        #expect(vm.acceptedSubmissionCount == 1)
        #expect(vm.rejectedSubmissionCount == 1)
    }

    // MARK: - Phase 8 completion bonuses

    @Test func testOnlyPangramSweepStacksWithLengthBonus() {
        let vm = GameViewModel(wordList: wordList)
        vm.startNewRound(with: pangramFixturePuzzle())
        #expect(submit("candles", on: vm) == true)
        #expect(vm.score == 28)
        #expect(vm.lastOutcome == .accepted(word: "candles", points: 14, isPangram: true))
        let expected: [CompletionEvent] = [
            .lengthComplete(length: 7, bonus: 7),
            .pangramSweep(bonus: 7, pangrams: ["candles"])
        ]
        #expect(vm.lastSubmissionBonusEvents == expected)
        #expect(vm.pendingCelebrations == vm.lastSubmissionBonusEvents)
        #expect(vm.sweepBonus == 7)
        #expect(vm.lengthBonusTotal == 7)
        #expect(vm.maxPossibleScore == 44)
        #expect(vm.foundPangramCount == 1)
        #expect(vm.totalPangramCount == 1)
    }

    @Test func testSweepAwardsOnlyWhenLastPangramFound() {
        let vm = GameViewModel(wordList: wordList)
        vm.startNewRound(with: twoPangramFixturePuzzle())
        #expect(submit("cabined", on: vm) == true)
        #expect(vm.score == 21)
        #expect(vm.sweepBonus == 0)
        #expect(vm.lastSubmissionBonusEvents == [.lengthComplete(length: 7, bonus: 7)])
        #expect(vm.foundPangramCount == 1)
        #expect(vm.totalPangramCount == 2)
        #expect(submit("abidance", on: vm) == true)
        #expect(vm.score == 58)
        let expected: [CompletionEvent] = [
            .lengthComplete(length: 8, bonus: 8),
            .pangramSweep(bonus: 14, pangrams: ["cabined", "abidance"])
        ]
        #expect(vm.lastSubmissionBonusEvents == expected)
        #expect(vm.sweepBonus == 14)
    }

    @Test func testLengthBonusOnlyWhenGroupComplete() {
        let vm = GameViewModel(wordList: wordList)
        vm.startNewRound(with: twoPangramFixturePuzzle())
        #expect(submit("cabin", on: vm) == true)
        #expect(vm.score == 5)
        #expect(vm.lastSubmissionBonusEvents.isEmpty)
        #expect(submit("dance", on: vm) == true)
        #expect(vm.score == 15)
        #expect(vm.lastSubmissionBonusEvents == [.lengthComplete(length: 5, bonus: 5)])
        #expect(vm.completedLengths == [5])
    }

    @Test func testLengthBonusAwardedOncePerLength() {
        let vm = GameViewModel(wordList: wordList)
        vm.startNewRound(with: pangramFixturePuzzle())
        #expect(submit("cane", on: vm) == true)
        #expect(submit("clan", on: vm) == true)
        #expect(vm.lengthBonusTotal == 4)
        #expect(vm.completedLengths == [4])
        let scoreBefore = vm.score
        #expect(submit("cane", on: vm) == false)
        #expect(vm.lengthBonusTotal == 4)
        #expect(vm.score == scoreBefore)
    }

    @Test func testEmptyPangramSetNeverSweeps() {
        let vm = GameViewModel(wordList: wordList)
        vm.startNewRound(with: fixturePuzzle())
        #expect(submit("tentacled", on: vm) == true)
        #expect(vm.score == 9)
        #expect(vm.lastSubmissionBonusEvents.isEmpty)
        #expect(vm.sweepBonus == 0)
        for w in ["cane", "lance", "candle", "canted", "dental"] {
            _ = submit(w, on: vm)
        }
        #expect(vm.sweepBonus == 0)
        let hasSweep = vm.pendingCelebrations.contains {
            if case .pangramSweep = $0 { return true }
            return false
        }
        #expect(!hasSweep)
    }

    @Test func testWordOutsideValidWordsNeverAwardsLengthBonus() {
        let vm = GameViewModel(wordList: wordList)
        vm.startNewRound(with: fixturePuzzle())
        #expect(submit("tentacled", on: vm) == true)
        #expect(vm.completedLengths.isEmpty)
        #expect(vm.lengthBonusTotal == 0)
    }

    @Test func testMaxPossibleScoreExcludesBonuses() {
        let vm = GameViewModel(wordList: wordList)
        vm.startNewRound(with: pangramFixturePuzzle())
        #expect(vm.maxPossibleScore == 44)
        _ = submit("candles", on: vm)
        #expect(vm.maxPossibleScore == 44)
    }

    @Test func testProgressFractionExceedsOneAndRankIsMythic() {
        let vm = GameViewModel(wordList: wordList)
        vm.startNewRound(with: pangramFixturePuzzle())
        for w in ["cane", "clan", "lance", "lanes", "candle", "decals", "scaled", "candles"] {
            #expect(submit(w, on: vm) == true)
        }
        #expect(vm.score == 73)
        #expect(abs(vm.progressFraction - 73.0 / 44.0) < 1e-9)
        #expect(vm.rank == .mythicGrandmaster)
        #expect(vm.sweepBonus == 7)
        #expect(vm.lengthBonusTotal == 22)
    }

    @Test func testProgressFractionZeroWithoutPuzzle() {
        let vm = GameViewModel(wordList: wordList)
        #expect(vm.progressFraction == 0)
    }

    @Test func testFinishRoundPersistsBonusInclusiveScore() throws {
        let container = try PersistenceStore.makeContainer(inMemory: true)
        let store = PersistenceStore(container: container)
        let vm = GameViewModel(wordList: wordList, persistenceStore: store)
        vm.startNewRound(with: pangramFixturePuzzle())
        _ = submit("candles", on: vm)
        vm.finishRound()
        #expect(store.bestScore() == 28)
    }

    @Test func testStartNewRoundResetsBonusState() {
        let vm = GameViewModel(wordList: wordList)
        vm.startNewRound(with: pangramFixturePuzzle())
        _ = submit("candles", on: vm)
        vm.startNewRound(with: pangramFixturePuzzle())
        #expect(vm.sweepBonus == 0)
        #expect(vm.lengthBonusTotal == 0)
        #expect(vm.completedLengths.isEmpty)
        #expect(vm.pendingCelebrations.isEmpty)
        #expect(vm.lastSubmissionBonusEvents.isEmpty)
        #expect(vm.foundPangramCount == 0)
        #expect(vm.totalPangramCount == 1)
        #expect(vm.acceptedSubmissionCount == 1)
    }

    @Test func testDequeueCelebrationIsFIFO() {
        let vm = GameViewModel(wordList: wordList)
        vm.startNewRound(with: pangramFixturePuzzle())
        _ = submit("candles", on: vm)
        #expect(vm.dequeueCelebration() == .lengthComplete(length: 7, bonus: 7))
        #expect(vm.dequeueCelebration() == .pangramSweep(bonus: 7, pangrams: ["candles"]))
        #expect(vm.dequeueCelebration() == nil)
    }

    @Test func testBonusStateIsCurrentWhenAcceptedCounterChanges() {
        let vm = GameViewModel(wordList: wordList)
        vm.startNewRound(with: pangramFixturePuzzle())
        _ = submit("candles", on: vm)
        #expect(vm.lastSubmissionBonusEvents.count == 2)
        #expect(vm.acceptedSubmissionCount == 1)
    }

    @Test func testRejectionMessagesAreExact() {
        #expect(RejectionReason.tooShort.message == "Too tiny!")
        #expect(RejectionReason.missingCenterLetter.message == "Forgot the middle!")
        #expect(RejectionReason.alreadyFound.message == "Got that one already")
        #expect(RejectionReason.notAWord.message == "Hmm, not a word")
        #expect(RejectionReason.allCases.count == 4)
    }

    // MARK: - Debug shortcuts (Debug builds only)

    #if DEBUG
    @Test func testDebugSolveStopsAtOrUnderMaxAndLeavesSweepPangram() {
        for puzzle in [twoPangramFixturePuzzle(), pangramFixturePuzzle()] {
            let vm = GameViewModel(wordList: wordList)
            vm.startNewRound(with: puzzle)
            vm.debugSolveToJustUnderMax()
            #expect(vm.progressFraction <= 1)
            #expect(vm.foundPangramCount < vm.totalPangramCount)
            #expect(vm.pendingCelebrations.isEmpty)
            #expect(vm.debugRemainingWords.last.map(vm.pangramSet.contains) == true)
            // Typing the rest in order crosses 100% live and fires the sweep last.
            while !vm.debugRemainingWords.isEmpty {
                vm.debugTypeNextRemainingWord()
                #expect(vm.submitCurrentWord() == true)
            }
            #expect(vm.progressFraction > 1)
            #expect(vm.sweepBonus > 0)
            #expect(vm.rank == .mythicGrandmaster)
        }
    }
    #endif
}
