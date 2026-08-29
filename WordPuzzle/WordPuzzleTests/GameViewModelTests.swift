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
        #expect(vm.lastOutcome == .rejected)
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
}
