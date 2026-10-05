import Foundation
import Observation

enum TutorialAction: Equatable {
    case letter(Character), delete, clearWord, submit, shuffle, scoreBar, finish, topBar
}
enum TutorialTarget: Equatable {
    case letter(Character), wordDisplay, delete, shuffle, scoreBar, finish
}
enum TutorialMode: Equatable { case firstLaunch, replay }

/// Delays are injected so unit tests run with zero waits. A `.zero` delay applies synchronously.
struct TutorialTiming {
    /// Build step: let the finished word sit on screen before step 2 clears it.
    var stepAdvanceDelay: Duration = .milliseconds(600)
    /// D-06 / Pitfall 5: shake (~0.4s) + "Forgot the middle!" must be seen BEFORE the rule is explained.
    var missExplainDelay: Duration = .milliseconds(900)
    /// Let the Phase 8 length pill + sweep start before the banner moves on.
    var pangramAdvanceDelay: Duration = .milliseconds(1500)
    /// Pitfall 8: idle time on the pangram step before each hint level.
    var pangramHintDelay: Duration = .seconds(20)
    static let standard = TutorialTiming()
    static let immediate = TutorialTiming(stepAdvanceDelay: .zero, missExplainDelay: .zero,
                                          pangramAdvanceDelay: .zero, pangramHintDelay: .seconds(3600))
}

@MainActor
@Observable
final class TutorialController {
    /// D-07: a SEPARATE view-model with NO persistence store. Every write in GameViewModel is
    /// `persistenceStore?.…`, so this board cannot record a round start or a GameRecord, and
    /// `requestNextRound` (the paywall gate) is never called on it.
    let practice: GameViewModel
    private(set) var isActive = false
    private(set) var mode: TutorialMode = .firstLaunch
    private(set) var step: TutorialStep = .build
    /// Step 2 sub-state: the guided miss has happened and the rule is now explained.
    private(set) var hasMissed = false
    /// Step 4 sub-state: Delete done, now tap the word to clear.
    private(set) var hasDeleted = false
    /// Step 7 hints: 0 none, 1 text hint, 2 follow-the-glow.
    private(set) var pangramHintLevel = 0
    /// True while a delayed transition is pending; all guided input is ignored meanwhile.
    private(set) var isWaiting = false
    /// Set by WordPuzzleApp. Called after the flag is set and isActive is false.
    @ObservationIgnored var onExit: ((TutorialMode) -> Void)?

    @ObservationIgnored private let wordList: WordList
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let timing: TutorialTiming
    @ObservationIgnored private var pangramRejections = 0
    @ObservationIgnored private var pendingTask: Task<Void, Never>?
    @ObservationIgnored private var hintTask: Task<Void, Never>?

    init(wordList: WordList, defaults: UserDefaults = .standard, timing: TutorialTiming = .standard) {
        self.wordList = wordList
        self.defaults = defaults
        self.timing = timing
        self.practice = GameViewModel(wordList: wordList, persistenceStore: nil)
    }

    var isGuided: Bool { isActive && step != .ready }
    var copy: TutorialCopy { TutorialText.copy(for: step, hasMissed: hasMissed, pangramHintLevel: pangramHintLevel) }
    /// Dim non-target controls/tiles: guided steps, except the free-form pangram step until hint level 2.
    var dimsBoard: Bool { guard isGuided else { return false }; return step == .pangram ? pangramHintLevel >= 2 : true }

    // MARK: - Script helpers

    private var current: String { practice.currentWord.lowercased() }

    private var target: String? {
        switch step {
        case .build, .swipe: return PracticePuzzle.buildWord
        case .centerMiss: return hasMissed ? nil : PracticePuzzle.missWord
        case .drag: return PracticePuzzle.dragWord
        case .pangram: return pangramHintLevel >= 2 ? PracticePuzzle.pangram : nil
        default: return nil
        }
    }

    private func nextExpected(for word: String) -> Character? {
        let cur = current
        guard word.hasPrefix(cur), cur.count < word.count else { return nil }
        return word[word.index(word.startIndex, offsetBy: cur.count)]
    }

    private var nextExpected: Character? {
        guard let t = target else { return nil }
        return nextExpected(for: t)
    }

    var highlightTarget: TutorialTarget? {
        guard isActive, !isWaiting else { return nil }
        switch step {
        case .build:
            if current == PracticePuzzle.buildWord { return nil }
            return nextExpected.map { .letter($0) }
        case .centerMiss:
            if hasMissed { return .letter(PracticePuzzle.centerLetter) }
            fallthrough
        case .swipe, .drag:
            guard let t = target else { return nil }
            if current == t { return .wordDisplay }
            return nextExpected.map { .letter($0) }
        case .fixMistake: return hasDeleted ? .wordDisplay : .delete
        case .shuffle: return .shuffle
        case .pangram:
            guard pangramHintLevel >= 2 else { return nil }
            if let n = nextExpected { return .letter(n) }
            return current.isEmpty ? nil : .wordDisplay
        case .scoreBar: return .scoreBar
        case .ready: return .finish
        }
    }

    // MARK: - Lifecycle

    func begin(mode: TutorialMode) {
        pendingTask?.cancel(); pendingTask = nil
        hintTask?.cancel(); hintTask = nil
        self.mode = mode
        guard wordList.isLoaded else {
            TutorialFlag.markSeen(in: defaults)
            isActive = false
            onExit?(mode)
            return
        }
        practice.startNewRound(with: PracticePuzzle.puzzle)
        step = .build
        hasMissed = false
        hasDeleted = false
        pangramHintLevel = 0
        pangramRejections = 0
        isWaiting = false
        isActive = true
    }

    func allows(_ action: TutorialAction) -> Bool {
        if !isActive || step == .ready { return true }
        if isWaiting { return false }
        func isNext(_ c: Character, _ word: String) -> Bool {
            nextExpected(for: word) == Character(c.lowercased())
        }
        switch step {
        case .build:
            if case .letter(let c) = action { return isNext(c, PracticePuzzle.buildWord) }
            return false
        case .centerMiss:
            if hasMissed {
                if case .letter(let c) = action {
                    return Character(c.lowercased()) == PracticePuzzle.centerLetter && current.isEmpty
                }
                return false
            }
            switch action {
            case .letter(let c): return isNext(c, PracticePuzzle.missWord)
            case .submit: return current == PracticePuzzle.missWord
            default: return false
            }
        case .swipe, .drag:
            let t = target ?? ""
            switch action {
            case .letter(let c): return isNext(c, t)
            case .submit: return current == t
            default: return false
            }
        case .fixMistake:
            switch action {
            case .delete: return !hasDeleted
            case .clearWord: return hasDeleted
            default: return false
            }
        case .shuffle:
            return action == .shuffle
        case .pangram:
            switch action {
            case .letter, .delete, .clearWord, .submit, .shuffle: return true
            default: return false
            }
        case .scoreBar:
            return action == .scoreBar
        case .ready:
            return true
        }
    }

    @discardableResult
    func send(_ action: TutorialAction) -> Bool {
        guard isActive, allows(action) else { return false }
        switch action {
        case .letter(let c):
            practice.append(c)
            if step == .build, current == PracticePuzzle.buildWord {
                after(timing.stepAdvanceDelay) { [self] in
                    practice.clearCurrentWord()
                    step = .centerMiss
                }
            } else if step == .centerMiss, hasMissed {
                step = .swipe
            }
        case .submit:
            practice.submitCurrentWord()
            switch step {
            case .centerMiss:
                if practice.lastOutcome == .rejected(.missingCenterLetter) {
                    after(timing.missExplainDelay) { [self] in hasMissed = true }
                }
            case .swipe:
                if case .accepted = practice.lastOutcome {
                    step = .fixMistake
                    for ch in PracticePuzzle.fixPrefill { practice.append(ch) }
                }
            case .drag:
                if case .accepted = practice.lastOutcome { step = .shuffle }
            case .pangram:
                if case .accepted(_, _, true) = practice.lastOutcome {
                    hintTask?.cancel(); hintTask = nil
                    after(timing.pangramAdvanceDelay) { [self] in step = .scoreBar }
                } else if case .rejected = practice.lastOutcome {
                    pangramRejections += 1
                    let level = pangramRejections >= 4 ? 2 : (pangramRejections >= 2 ? 1 : 0)
                    pangramHintLevel = max(pangramHintLevel, level)
                }
            default: break
            }
        case .delete:
            practice.deleteLast()
            if step == .fixMistake { hasDeleted = true }
        case .clearWord:
            practice.clearCurrentWord()
            if step == .fixMistake, hasDeleted { step = .drag }
        case .shuffle:
            let did = practice.shuffleOuterLetters()
            if did, step == .shuffle {
                step = .pangram
                startHintTimer()
            }
            return did
        case .scoreBar, .topBar:
            return true
        case .finish:
            exit()
            return true
        }
        return true
    }

    /// Advance on DISMISS of the found-words sheet so the Ready card is not hidden behind it.
    func foundWordsDismissed() {
        if isActive, step == .scoreBar { step = .ready }
    }

    func skip() { exit() }

    private func exit() {
        pendingTask?.cancel(); pendingTask = nil
        hintTask?.cancel(); hintTask = nil
        isWaiting = false
        TutorialFlag.markSeen(in: defaults)
        isActive = false
        onExit?(mode)
    }

    private func after(_ delay: Duration, _ work: @escaping () -> Void) {
        if delay == .zero { work(); return }
        isWaiting = true
        pendingTask?.cancel()
        pendingTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: delay)
            guard let self, !Task.isCancelled, self.isActive else { return }
            self.isWaiting = false
            work()
        }
    }

    private func startHintTimer() {
        hintTask?.cancel()
        let delay = timing.pangramHintDelay
        hintTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: delay)
            guard let self, !Task.isCancelled, self.isActive, self.step == .pangram else { return }
            self.pangramHintLevel = max(self.pangramHintLevel, 1)
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled, self.isActive, self.step == .pangram else { return }
            self.pangramHintLevel = max(self.pangramHintLevel, 2)
        }
    }
}
