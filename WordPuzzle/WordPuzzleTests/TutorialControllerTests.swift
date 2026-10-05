import Testing
import Foundation
@testable import WordPuzzle

@Suite(.serialized)
@MainActor
final class TutorialControllerTests {
    let wordList: WordList
    let suiteName = "TutorialControllerTests-\(UUID().uuidString)"
    let defaults: UserDefaults

    init() async throws {
        wordList = WordList()
        await wordList.load()
        defaults = UserDefaults(suiteName: suiteName)!
    }

    deinit { UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName) }

    private func make(_ timing: TutorialTiming = .immediate) -> TutorialController {
        let c = TutorialController(wordList: wordList, defaults: defaults, timing: timing)
        c.begin(mode: .firstLaunch)
        return c
    }

    private func play(_ word: String, on c: TutorialController) {
        for ch in word { c.send(.letter(ch)) }
    }

    /// Drives the script until `target` is the current step (immediate timing).
    private func drive(_ c: TutorialController, to target: TutorialStep) {
        for _ in 0..<20 where c.step != target {
            switch c.step {
            case .build: play("pond", on: c)
            case .centerMiss:
                if !c.hasMissed { play("hold", on: c); c.send(.submit) } else { c.send(.letter("p")) }
            case .swipe: play("ond", on: c); c.send(.submit)
            case .fixMistake:
                if !c.hasDeleted { c.send(.delete) } else { c.send(.clearWord) }
            case .drag: play("plod", on: c); c.send(.submit)
            case .shuffle:
                c.send(.shuffle)
            case .pangram:
                play("dolphin", on: c); c.send(.submit)
            case .scoreBar: c.foundWordsDismissed()
            case .ready: return
            }
        }
    }

    // MARK: - Script

    @Test func testBeginStartsBuildStep() {
        let c = make()
        #expect(c.isActive)
        #expect(c.step == .build)
        #expect(c.practice.roundPhase == .playing)
        #expect(c.practice.centerLetter == "p")
        #expect(c.practice.currentWord == "")
    }

    @Test func testBuildGatesInput() {
        let c = make()
        #expect(!c.allows(.letter("o")))
        #expect(c.allows(.letter("p")))
        #expect(!c.send(.letter("o")))
        #expect(c.practice.currentWord == "")
        for a in [TutorialAction.submit, .shuffle, .delete, .clearWord, .scoreBar, .finish, .topBar] {
            #expect(!c.allows(a))
        }
        #expect(c.highlightTarget == .letter("p"))
    }

    @Test func testBuildAdvancesToCenterMiss() {
        let c = make()
        play("pond", on: c)
        #expect(c.step == .centerMiss)
        #expect(c.practice.currentWord == "")
    }

    @Test func testCenterMissFlow() {
        let c = make()
        drive(c, to: .centerMiss)
        #expect(!c.allows(.letter("p")))
        play("hol", on: c)
        #expect(!c.allows(.submit))
        play("d", on: c)
        #expect(c.highlightTarget == .wordDisplay)
        #expect(c.allows(.submit))
        c.send(.submit)
        #expect(c.practice.lastOutcome == .rejected(.missingCenterLetter))
        #expect(c.hasMissed)
        #expect(c.allows(.letter("p")))
        #expect(!c.allows(.letter("o")))
        #expect(c.highlightTarget == .letter("p"))
        c.send(.letter("p"))
        #expect(c.step == .swipe)
        #expect(c.practice.currentWord == "p")
    }

    @Test func testSwipeAcceptsPondThenPrefills() {
        let c = make()
        drive(c, to: .swipe)
        play("ond", on: c)
        c.send(.submit)
        #expect(c.practice.foundWords.contains("pond"))
        #expect(c.step == .fixMistake)
        #expect(c.practice.currentWord == "polo")
    }

    @Test func testFixMistakeDeleteThenClear() {
        let c = make()
        drive(c, to: .fixMistake)
        #expect(c.highlightTarget == .delete)
        #expect(c.allows(.delete))
        #expect(!c.allows(.clearWord))
        c.send(.delete)
        #expect(c.practice.currentWord == "pol")
        #expect(c.highlightTarget == .wordDisplay)
        #expect(c.allows(.clearWord))
        #expect(!c.allows(.delete))
        c.send(.clearWord)
        #expect(c.practice.currentWord == "")
        #expect(c.step == .drag)
    }

    @Test func testDragThenShuffleThenPangram() {
        let c = make()
        drive(c, to: .drag)
        play("plod", on: c)
        c.send(.submit)
        #expect(c.step == .shuffle)
        #expect(c.highlightTarget == .shuffle)
        #expect(!c.allows(.letter("p")))
        #expect(c.send(.shuffle))
        #expect(c.step == .pangram)
    }

    @Test func testPangramGatingAndAdvance() {
        let c = make()
        drive(c, to: .pangram)
        for a in [TutorialAction.letter("d"), .delete, .clearWord, .submit, .shuffle] { #expect(c.allows(a)) }
        for a in [TutorialAction.scoreBar, .finish, .topBar] { #expect(!c.allows(a)) }
        #expect(!c.dimsBoard)
        play("dolphin", on: c)
        c.send(.submit)
        #expect(c.step == .scoreBar)
    }

    @Test func testScoreBarAdvancesOnDismiss() {
        let c = make()
        drive(c, to: .scoreBar)
        #expect(c.highlightTarget == .scoreBar)
        #expect(!c.allows(.letter("p")))
        #expect(c.send(.scoreBar))
        #expect(c.step == .scoreBar)
        c.foundWordsDismissed()
        #expect(c.step == .ready)
        #expect(!c.isGuided)
        #expect(c.allows(.finish))
        #expect(c.allows(.letter("z")))
        #expect(c.highlightTarget == .finish)
    }

    // MARK: - Exit / free / replay

    @Test func testFreeAndUnrecordedThenFirstLaunchHandoff() throws {
        let store = PersistenceStore(container: try PersistenceStore.makeContainer(inMemory: true))
        let real = GameViewModel(wordList: wordList, persistenceStore: store)
        let c = make()
        c.onExit = { mode in
            if mode == .firstLaunch, real.roundPhase == .loading { real.requestNextRound(isPremium: false) }
        }
        var exits = 0
        let inner = c.onExit
        c.onExit = { exits += 1; inner?($0) }
        drive(c, to: .ready)
        #expect(c.step == .ready)
        #expect(c.practice.roundPhase == .playing)
        #expect(store.puzzlesPlayedToday() == 0)
        #expect(store.totalGamesPlayed() == 0)
        #expect(store.hasAnyHistory() == false)
        c.send(.finish)
        #expect(TutorialFlag.state(in: defaults) == true)
        #expect(!c.isActive)
        #expect(exits == 1)
        #expect(real.roundPhase == .playing)
        #expect(store.puzzlesPlayedToday() == 1)
        #expect(store.totalGamesPlayed() == 0)
    }

    @Test func testSkipAtSwipe() {
        let c = make()
        var modes: [TutorialMode] = []
        c.onExit = { modes.append($0) }
        drive(c, to: .swipe)
        c.skip()
        #expect(TutorialFlag.state(in: defaults) == true)
        #expect(!c.isActive)
        #expect(modes == [.firstLaunch])
    }

    @Test func testFinishRejectedBeforeReady() {
        let c = make()
        #expect(!c.send(.finish))
        #expect(TutorialFlag.state(in: defaults) == nil)
        #expect(c.isActive)
    }

    @Test func testReplayLeavesRealRoundUntouched() throws {
        let store = PersistenceStore(container: try PersistenceStore.makeContainer(inMemory: true))
        let real = GameViewModel(wordList: wordList, persistenceStore: store)
        real.startNewRound(with: Puzzle(letters: Set("acdelnt"), centerLetter: "a",
                                        validWords: ["cane", "lance", "candle", "canted", "dental"], pangrams: []))
        for ch in "cane" { real.append(ch) }
        real.submitCurrentWord()
        real.append("l")
        let c = TutorialController(wordList: wordList, defaults: defaults, timing: .immediate)
        var modes: [TutorialMode] = []
        c.onExit = { modes.append($0) }
        c.begin(mode: .replay)
        drive(c, to: .fixMistake)
        c.skip()
        #expect(modes == [.replay])
        #expect(real.roundPhase == .playing)
        #expect(real.foundWords == ["cane"])
        #expect(real.currentWord == "l")
        #expect(store.puzzlesPlayedToday() == 1)
    }

    @Test func testInterruptionRestartsFromStepOne() {
        let c = make()
        drive(c, to: .swipe)
        c.begin(mode: .firstLaunch)
        #expect(c.step == .build)
        #expect(!c.hasMissed)
        #expect(c.practice.currentWord == "")
        #expect(c.practice.foundWords.isEmpty)
        #expect(TutorialFlag.state(in: defaults) == nil)
    }

    @Test func testUnloadedWordListSilentlySkips() {
        let c = TutorialController(wordList: WordList(), defaults: defaults, timing: .immediate)
        var modes: [TutorialMode] = []
        c.onExit = { modes.append($0) }
        c.begin(mode: .firstLaunch)
        #expect(TutorialFlag.state(in: defaults) == true)
        #expect(!c.isActive)
        #expect(modes == [.firstLaunch])
    }

    // MARK: - Timing

    @Test func testMissExplanationIsDelayed() async throws {
        let timing = TutorialTiming(stepAdvanceDelay: .zero, missExplainDelay: .milliseconds(150),
                                    pangramAdvanceDelay: .zero, pangramHintDelay: .seconds(3600))
        let c = make(timing)
        drive(c, to: .centerMiss)
        play("hold", on: c)
        c.send(.submit)
        #expect(!c.hasMissed)
        #expect(!c.copy.instruction.contains("gold"))
        #expect(c.isWaiting)
        #expect(!c.allows(.letter("p")))
        try await Task.sleep(for: .milliseconds(400))
        #expect(c.hasMissed)
        #expect(c.copy.instruction.contains("gold letter in the middle"))
    }

    @Test func testPangramRejectionHints() {
        let c = make()
        drive(c, to: .pangram)
        for _ in 0..<2 { play("hoo", on: c); c.send(.submit) }
        #expect(c.pangramHintLevel == 1)
        for _ in 0..<2 { play("hoo", on: c); c.send(.submit) }
        #expect(c.pangramHintLevel == 2)
        #expect(c.highlightTarget == .letter("d"))
        #expect(c.dimsBoard)
    }

    @Test func testPangramIdleHint() async throws {
        let timing = TutorialTiming(stepAdvanceDelay: .zero, missExplainDelay: .zero,
                                    pangramAdvanceDelay: .zero, pangramHintDelay: .milliseconds(100))
        let c = make(timing)
        drive(c, to: .pangram)
        try await Task.sleep(for: .milliseconds(300))
        #expect(c.pangramHintLevel >= 1)
    }

    @Test func testReplayFinishReportsReplayMode() {
        let c = TutorialController(wordList: wordList, defaults: defaults, timing: .immediate)
        var modes: [TutorialMode] = []
        c.onExit = { modes.append($0) }
        c.begin(mode: .replay)
        drive(c, to: .ready)
        c.send(.finish)
        #expect(modes == [.replay])
        #expect(c.practice.roundPhase == .playing)
    }
}
