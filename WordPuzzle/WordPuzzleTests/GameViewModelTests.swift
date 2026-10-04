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

    private func submit(_ word: String, on vm: GameViewModel) -> Bool {
        for ch in word { vm.append(ch) }
        return vm.submitCurrentWord()
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
        #expect(vm.score == 1)
        #expect(vm.foundCount == 1)
        #expect(submit("lance", on: vm) == true)
        #expect(vm.score == 6)
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
        #expect(vm.score == 1)
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
        #expect(vm.score == 1)
        #expect(vm.foundWords == ["cane"])
        #expect(vm.acceptedSubmissionCount == 1)
        #expect(vm.rejectedSubmissionCount == 1)
    }

    @Test func testRejectionMessagesAreExact() {
        #expect(RejectionReason.tooShort.message == "Too tiny!")
        #expect(RejectionReason.missingCenterLetter.message == "Forgot the middle!")
        #expect(RejectionReason.alreadyFound.message == "Got that one already")
        #expect(RejectionReason.notAWord.message == "Hmm, not a word")
        #expect(RejectionReason.allCases.count == 4)
    }
}
