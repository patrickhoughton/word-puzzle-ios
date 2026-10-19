import Testing
import Foundation
import SwiftData
@testable import WordPuzzle

@Suite(.serialized)
@MainActor
final class RoundPersistenceTests {
    let wordList: WordList

    init() async throws {
        wordList = WordList()
        await wordList.load()
    }

    private func twoPangramFixturePuzzle() -> Puzzle {
        Puzzle(
            letters: Set("abcdein"),
            centerLetter: "a",
            validWords: ["bead", "cabin", "dance", "cabined", "abidance"],
            pangrams: ["cabined", "abidance"]
        )
    }

    private struct Env {
        let defaults: UserDefaults
        let suiteName: String
        let persistence: PersistenceStore
        let roundStore: RoundSnapshotStore
    }

    private func makeEnv() throws -> Env {
        let name = "RoundPersistenceTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        let persistence = PersistenceStore(container: try PersistenceStore.makeContainer(inMemory: true))
        return Env(defaults: defaults, suiteName: name, persistence: persistence,
                   roundStore: RoundSnapshotStore(defaults: defaults))
    }

    private func makeVM(_ env: Env, withRoundStore: Bool = true) -> GameViewModel {
        GameViewModel(wordList: wordList, persistenceStore: env.persistence,
                      roundStore: withRoundStore ? env.roundStore : nil)
    }

    private func submit(_ word: String, on vm: GameViewModel) {
        for ch in word { vm.append(ch) }
        vm.submitCurrentWord()
    }

    private func expectSameState(_ a: GameViewModel, _ b: GameViewModel) {
        #expect(b.centerLetter == a.centerLetter)
        #expect(b.puzzle!.letters == a.puzzle!.letters)
        #expect(b.puzzle!.validWords == a.puzzle!.validWords)
        #expect(b.pangramSet == a.pangramSet)
        #expect(b.foundWords == a.foundWords)
        #expect(b.score == a.score)
        #expect(b.sweepBonus == a.sweepBonus)
        #expect(b.lengthBonusTotal == a.lengthBonusTotal)
        #expect(b.completedLengths == a.completedLengths)
        #expect(b.foundPangramCount == a.foundPangramCount)
        #expect(b.maxPossibleScore == a.maxPossibleScore)
        #expect(Set(b.outerLetters) == Set(a.outerLetters))
        #expect(b.roundPhase == .playing)
        #expect(b.pendingCelebrations.isEmpty)
        #expect(b.currentWord == "")
    }

    @Test func testFullRoundTrip() throws {
        let env = try makeEnv()
        defer { env.defaults.removePersistentDomain(forName: env.suiteName) }
        let vm1 = makeVM(env)
        vm1.startNewRound(with: twoPangramFixturePuzzle())
        for w in ["bead", "cabin", "dance", "cabined", "abidance"] { submit(w, on: vm1) }
        #expect(vm1.sweepBonus > 0)
        let vm2 = makeVM(env)
        #expect(vm2.restoreSavedRound() == true)
        expectSameState(vm1, vm2)
    }

    @Test func testPartialRoundTrip() throws {
        let env = try makeEnv()
        defer { env.defaults.removePersistentDomain(forName: env.suiteName) }
        let vm1 = makeVM(env)
        vm1.startNewRound(with: twoPangramFixturePuzzle())
        // "cabin" leaves the 5-letter group ("dance") open, so no length bonus yet.
        // ("bead" would complete the only 4-letter group and earn one.)
        submit("cabin", on: vm1)
        let vm2 = makeVM(env)
        #expect(vm2.restoreSavedRound() == true)
        expectSameState(vm1, vm2)
        #expect(vm2.lengthBonusTotal == 0)
        #expect(vm2.sweepBonus == 0)
    }

    @Test func testRelaunchRecordsNoNewStart() throws {
        let env = try makeEnv()
        defer { env.defaults.removePersistentDomain(forName: env.suiteName) }
        let vm1 = makeVM(env)
        vm1.startNewRound(with: twoPangramFixturePuzzle())
        #expect(env.persistence.puzzlesPlayedToday() == 1)
        let vm2 = makeVM(env)
        vm2.resumeOrRequestNextRound(isPremium: false)
        #expect(env.persistence.puzzlesPlayedToday() == 1)
        #expect(vm2.roundPhase == .playing)
    }

    @Test func testRestoredRoundNeverPaywalled() throws {
        let env = try makeEnv()
        defer { env.defaults.removePersistentDomain(forName: env.suiteName) }
        let vm1 = makeVM(env)
        vm1.startNewRound(with: twoPangramFixturePuzzle())
        while env.persistence.puzzlesPlayedToday() < GameViewModel.freePuzzlesPerDay {
            env.persistence.recordRoundStarted()
        }
        let vm2 = makeVM(env)
        vm2.resumeOrRequestNextRound(isPremium: false)
        #expect(vm2.roundPhase == .playing)
        #expect(vm2.puzzle?.validWords == twoPangramFixturePuzzle().validWords)
    }

    @Test func testFinishClearsSave() throws {
        let env = try makeEnv()
        defer { env.defaults.removePersistentDomain(forName: env.suiteName) }
        let vm1 = makeVM(env)
        vm1.startNewRound(with: twoPangramFixturePuzzle())
        while env.persistence.puzzlesPlayedToday() < GameViewModel.freePuzzlesPerDay {
            env.persistence.recordRoundStarted()
        }
        vm1.finishRound()
        #expect(env.roundStore.load() == nil)
        let vm2 = makeVM(env)
        vm2.resumeOrRequestNextRound(isPremium: false)
        #expect(vm2.roundPhase == .paywalled)
    }

    @Test func testCorruptSaveFallsBack() throws {
        let env = try makeEnv()
        defer { env.defaults.removePersistentDomain(forName: env.suiteName) }
        env.defaults.set(Data("garbage".utf8), forKey: RoundSnapshotStore.key)
        #expect(env.roundStore.load() == nil)
        let vm = makeVM(env)
        #expect(vm.restoreSavedRound() == false)
        let before = env.persistence.puzzlesPlayedToday()
        vm.resumeOrRequestNextRound(isPremium: true)
        #expect(vm.roundPhase == .playing)
        #expect(env.persistence.puzzlesPlayedToday() == before + 1)
    }

    @Test func testMissingSave() throws {
        let env = try makeEnv()
        defer { env.defaults.removePersistentDomain(forName: env.suiteName) }
        let vm = makeVM(env)
        #expect(vm.restoreSavedRound() == false)
        #expect(vm.roundPhase == .loading)
    }

    @Test func testInvalidSnapshotsRejected() throws {
        let env = try makeEnv()
        defer { env.defaults.removePersistentDomain(forName: env.suiteName) }
        let bad: [RoundSnapshot] = [
            RoundSnapshot(letters: "bcdeinz", centerLetter: "a", validWords: ["bead"], pangrams: [], foundWords: []),
            RoundSnapshot(letters: "abcdei", centerLetter: "a", validWords: ["bead"], pangrams: [], foundWords: []),
            RoundSnapshot(letters: "abcdein", centerLetter: "a", validWords: [], pangrams: [], foundWords: []),
        ]
        for snap in bad {
            env.roundStore.save(snap)
            let vm = makeVM(env)
            #expect(vm.restoreSavedRound() == false)
        }
    }

    @Test func testEachAcceptedWordUpdatesSave() throws {
        let env = try makeEnv()
        defer { env.defaults.removePersistentDomain(forName: env.suiteName) }
        let vm = makeVM(env)
        vm.startNewRound(with: twoPangramFixturePuzzle())
        #expect(env.roundStore.load()?.foundWords == [])
        submit("bead", on: vm)
        #expect(env.roundStore.load()!.foundWords.contains("bead"))
        submit("cabin", on: vm)
        #expect(env.roundStore.load()!.foundWords == ["cabin", "bead"])
    }

    @Test func testVMWithoutRoundStoreNeverWrites() throws {
        let env = try makeEnv()
        defer { env.defaults.removePersistentDomain(forName: env.suiteName) }
        let vm = makeVM(env, withRoundStore: false)
        vm.startNewRound(with: twoPangramFixturePuzzle())
        submit("bead", on: vm)
        #expect(env.defaults.object(forKey: RoundSnapshotStore.key) == nil)
    }
}
