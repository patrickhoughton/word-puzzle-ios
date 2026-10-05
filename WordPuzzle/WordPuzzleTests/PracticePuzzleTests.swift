import Testing
import Foundation
@testable import WordPuzzle

@Suite(.serialized)
@MainActor
final class PracticePuzzleTests {
    let wordList: WordList

    init() async throws {
        wordList = WordList()
        await wordList.load()
    }

    private func submit(_ word: String, in vm: GameViewModel) {
        for ch in word { vm.append(ch) }
        _ = vm.submitCurrentWord()
    }

    private func makeVM() -> GameViewModel {
        let vm = GameViewModel(wordList: wordList, persistenceStore: nil)
        vm.startNewRound(with: PracticePuzzle.puzzle)
        return vm
    }

    @Test func testEveryValidWordIsRealAndUsesCenter() {
        for w in PracticePuzzle.validWords {
            #expect(wordList.contains(w), "\(w) not in word list")
            #expect(w.count >= 4)
            #expect(w.contains(PracticePuzzle.centerLetter))
            #expect(Set(w).isSubset(of: PracticePuzzle.letters))
        }
    }

    @Test func testDolphinIsTheOnlyPangram() {
        #expect(PracticePuzzle.pangrams == ["dolphin"])
        for w in PracticePuzzle.validWords {
            let usesAll = Set(w) == PracticePuzzle.letters
            #expect(usesAll == (w == "dolphin"), "\(w)")
        }
    }

    @Test func testMissWordIsRejectedForMissingCenter() {
        let w = PracticePuzzle.missWord
        #expect(w.count >= 4)
        #expect(!w.contains("p"))
        #expect(Set(w).isSubset(of: PracticePuzzle.letters))
        #expect(wordList.contains(w))
        let vm = makeVM()
        submit(w, in: vm)
        #expect(vm.lastOutcome == .rejected(.missingCenterLetter))
    }

    @Test func testScriptedWordsAreValid() {
        for w in [PracticePuzzle.buildWord, PracticePuzzle.dragWord, PracticePuzzle.pangram] {
            #expect(PracticePuzzle.validWords.contains(w))
        }
        let vm = makeVM()
        for w in [PracticePuzzle.buildWord, PracticePuzzle.dragWord] {
            submit(w, in: vm)
            guard case .accepted = vm.lastOutcome else {
                Issue.record("\(w) not accepted: \(String(describing: vm.lastOutcome))")
                continue
            }
        }
    }

    @Test func testFixPrefillUsesPuzzleLetters() {
        #expect(Set(PracticePuzzle.fixPrefill).isSubset(of: PracticePuzzle.letters))
    }

    @Test func testDragWordHasNoConsecutiveRepeat() {
        let chars = Array(PracticePuzzle.dragWord)
        for i in 1..<chars.count { #expect(chars[i] != chars[i - 1]) }
    }

    @Test func testScriptedWordsCompleteNoLengthGroupEarly() {
        let scripted = [PracticePuzzle.buildWord, PracticePuzzle.dragWord]
        for length in Set(PracticePuzzle.validWords.map(\.count)) {
            let total = PracticePuzzle.validWords.filter { $0.count == length }.count
            let used = scripted.filter { $0.count == length }.count
            #expect(used < total)
        }
        let vm = makeVM()
        for w in scripted { submit(w, in: vm) }
        #expect(vm.completedLengths.isEmpty)
    }
}
