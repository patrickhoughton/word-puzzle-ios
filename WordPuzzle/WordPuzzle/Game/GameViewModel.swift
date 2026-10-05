import Foundation
import Observation

/// Phase 6 D-01: the four player-facing reasons a submission can be rejected.
/// Outside-letter submissions fold into `.notAWord` (tap/drag input can't produce them).
/// Phase 999.10 (rejected-word logging) should key off `.notAWord` only.
enum RejectionReason: Equatable, CaseIterable {
    case tooShort
    case missingCenterLetter
    case alreadyFound
    case notAWord
}

extension RejectionReason {
    /// D-03 / D-04: fixed playful strings. Never interpolate the word or center letter.
    var message: String {
        switch self {
        case .tooShort:            return "Too tiny!"
        case .missingCenterLetter: return "Forgot the middle!"
        case .alreadyFound:        return "Got that one already"
        case .notAWord:            return "Hmm, not a word"
        }
    }
}

/// Result of one word submission (carries the rejection reason when rejected).
/// Drives the word-display feedback in WordDisplayView.
enum SubmissionOutcome: Equatable {
    case accepted(word: String, points: Int, isPangram: Bool)
    case rejected(RejectionReason)
}

/// One length bucket on the missed-words screen (D-11).
struct MissedWordGroup: Identifiable, Equatable {
    let length: Int
    let words: [String]
    var id: Int { length }
}

/// Phase 7 D-13/D-14: one found word as the in-round Found Words sheet shows it.
/// Points and the pangram flag are computed in the view-model so the view renders plain values.
struct FoundWord: Identifiable, Equatable {
    let text: String
    let points: Int
    let isPangram: Bool
    var id: String { text }
}

/// Phase 7 D-10/D-11/D-12: one length bucket on the Found Words sheet. `total` comes from the
/// puzzle's validWords, so a length with zero found words still has a group.
struct FoundWordGroup: Identifiable, Equatable {
    let length: Int
    /// Alphabetical (D-07), NOT order found.
    let found: [FoundWord]
    let total: Int
    var isComplete: Bool { found.count == total }
    var id: Int { length }
}

/// CONTEXT D-01..D-12. Owns ALL round state. Follows the project's established
/// `@Observable final class` service convention (WordList / PersistenceStore / EntitlementStore).
@MainActor
@Observable
final class GameViewModel {

    /// `paywalled` (Phase 4 / D-01): the free daily limit is reached and no new round
    /// may begin. A true dead-end — D-05: nothing is playable behind the paywall.
    enum RoundPhase: Equatable { case loading, playing, roundOver, paywalled }

    /// MON-01: free (non-premium) users may START this many rounds per local calendar day.
    /// Single source of truth — GameView reads this too, for the ScoreBarView counter (D-03).
    static let freePuzzlesPerDay = 3

    // MARK: - Dependencies
    private let wordList: WordList
    private let persistenceStore: PersistenceStore?

    // MARK: - Puzzle state
    private(set) var roundPhase: RoundPhase = .loading
    private(set) var puzzle: Puzzle?
    /// The 6 non-center letters, in current display order. Shuffle reorders this (D-03/PUZZ-04).
    private(set) var outerLetters: [Character] = []
    /// D-09: computed once per puzzle from ALL validWords.
    private(set) var maxPossibleScore: Int = 0
    private(set) var pangramSet: Set<String> = []

    // MARK: - Round state
    private(set) var currentWord: String = ""
    /// Most-recent-first.
    private(set) var foundWords: [String] = []
    private(set) var score: Int = 0
    private var foundWordSet: Set<String> = []

    // MARK: - Completion bonuses (Phase 8)
    /// D-01: total sweep bonus earned this round; 0 = not earned. Read by MissedWordsView (UI-SPEC 7).
    private(set) var sweepBonus: Int = 0
    /// D-14/D-15: sum of length-completion bonuses earned this round.
    private(set) var lengthBonusTotal: Int = 0
    /// D-18: lengths already rewarded this round, so a bonus never double-awards.
    private(set) var completedLengths: Set<Int> = []
    /// D-11: pangrams found so far (board counter + Found Words line).
    private(set) var foundPangramCount: Int = 0
    /// Events produced by the MOST RECENT accepted submission (0, 1 or 2). GameView reads this inside
    /// onChange(of: acceptedSubmissionCount) to decide whether the per-word sound is replaced.
    private(set) var lastSubmissionBonusEvents: [CompletionEvent] = []
    /// D-07/D-17: FIFO queue of celebrations GameView has not shown yet. Length before sweep for one word.
    private(set) var pendingCelebrations: [CompletionEvent] = []
    /// validWords count per length, computed once per round (O(1) detection).
    private var lengthTotals: [Int: Int] = [:]
    private var foundCountByLength: [Int: Int] = [:]
    /// Set(puzzle.validWords), set in startNewRound(with:); guards length counting.
    private var validWordSet: Set<String> = []

    // MARK: - Feedback state
    private(set) var lastOutcome: SubmissionOutcome?
    /// RESEARCH Pitfall 3: monotonic counters, never re-set Bools — `.sensoryFeedback(_:trigger:)`
    /// fires on CHANGE, so a Bool set to the same value twice would silently stop firing.
    private(set) var acceptedSubmissionCount: Int = 0
    private(set) var rejectedSubmissionCount: Int = 0
    /// RESEARCH Pitfall 2: gates drag input while the shuffle animation interpolates.
    private(set) var isShuffling: Bool = false
    /// Phase 10 D-08: monotonic haptic trigger. Bumped ONLY when a shuffle actually happens
    /// (button or double-tap). Never reset per round; `.sensoryFeedback` only needs it to change.
    private(set) var shuffleCount: Int = 0

    init(wordList: WordList, persistenceStore: PersistenceStore? = nil) {
        self.wordList = wordList
        self.persistenceStore = persistenceStore
    }

    // MARK: - Derived
    var centerLetter: Character { puzzle?.centerLetter ?? " " }
    var foundCount: Int { foundWords.count }
    var totalWordCount: Int { puzzle?.validWords.count ?? 0 }
    var rank: RankTier { RankTier.tier(score: score, maxScore: maxPossibleScore) }
    var totalPangramCount: Int { pangramSet.count }
    /// D-05: 0...unbounded; > 1 means bonuses pushed past max. ScoreBarView clamps its own ProgressView.
    var progressFraction: Double {
        guard maxPossibleScore > 0 else { return 0 }
        return Double(score) / Double(maxPossibleScore)
    }
    var missedWords: [String] {
        guard let puzzle else { return [] }
        return puzzle.validWords.filter { !foundWordSet.contains($0) }.sorted()
    }
    var missedWordGroups: [MissedWordGroup] {
        Dictionary(grouping: missedWords, by: \.count)
            .map { MissedWordGroup(length: $0.key, words: $0.value.sorted()) }
            .sorted { $0.length < $1.length }
    }

    /// Phase 7 D-06/D-07/D-11: every length present in validWords, ascending, each with its
    /// found words sorted alphabetically and the total for that length.
    var foundWordGroups: [FoundWordGroup] {
        guard let puzzle else { return [] }
        let totals = Dictionary(grouping: puzzle.validWords, by: \.count).mapValues(\.count)
        let foundByLength = Dictionary(grouping: foundWords, by: \.count)
        return totals.sorted { $0.key < $1.key }.map { length, total in
            let found = (foundByLength[length] ?? []).sorted().map { word in
                let isPangram = pangramSet.contains(word)
                return FoundWord(
                    text: word,
                    points: ScoreCalculator.points(for: word, isPangram: isPangram),
                    isPangram: isPangram
                )
            }
            return FoundWordGroup(length: length, found: found, total: total)
        }
    }

    // MARK: - Round lifecycle
    /// D-01: the SINGLE gate-check funnel for both paywall trigger points —
    /// (1) "Next Puzzle" after finishing a round, and (2) the launch-time check on a
    /// relaunch when the limit is already reached.
    ///
    /// Deliberately a discrete decision, NOT a reactive/derived `isLocked` boolean:
    /// `puzzlesPlayedToday()` counts round STARTS (D-02), so a derived boolean would
    /// become true the instant round 3 begins and would pre-empt round 3's own
    /// missed-words recap. Ask the question only when a NEW round is requested.
    ///
    /// `isPremium` is passed in rather than injected — GameViewModel stays decoupled
    /// from EntitlementStore's type and its existing test seams keep their shape.
    func requestNextRound(isPremium: Bool) {
        let startedToday = persistenceStore?.puzzlesPlayedToday() ?? 0
        if !isPremium, startedToday >= Self.freePuzzlesPerDay {
            roundPhase = .paywalled
        } else {
            startNewRound()
        }
    }

    /// D-12: generates the next puzzle and resets all round state.
    func startNewRound() {
        #if DEBUG
        // App Store screenshot staging (05-07): `-ScreenshotPuzzle harmony:r` pins every
        // round to a known, photogenic puzzle. Compiled out of Release builds.
        if wordList.isLoaded,
           let spec = UserDefaults.standard.string(forKey: "ScreenshotPuzzle"),
           let staged = stagedPuzzle(spec: spec, from: wordList) {
            startNewRound(with: staged)
            return
        }
        #endif
        guard wordList.isLoaded, let generated = try? generatePuzzle(from: wordList) else {
            roundPhase = .loading
            return
        }
        startNewRound(with: generated)
    }

    /// Test seam — the deterministic path used by `startNewRound()`.
    ///
    /// D-02: recording the round start HERE (after a Puzzle actually exists) is what makes
    /// an abandoned round count toward the daily limit. Deliberately not driven by
    /// ScenePhase/background notifications — those are not guaranteed to fire before a
    /// hard kill; writing at start time captures normal and abandoned rounds identically.
    func startNewRound(with puzzle: Puzzle) {
        persistenceStore?.recordRoundStarted()
        self.puzzle = puzzle
        self.pangramSet = Set(puzzle.pangrams)
        self.maxPossibleScore = ScoreCalculator.score(for: puzzle.validWords, pangrams: pangramSet)
        self.outerLetters = Array(puzzle.letters.subtracting([puzzle.centerLetter])).shuffled()
        self.currentWord = ""
        self.foundWords = []
        self.foundWordSet = []
        self.score = 0
        self.lastOutcome = nil
        self.lengthTotals = Dictionary(grouping: puzzle.validWords, by: \.count).mapValues(\.count)
        self.foundCountByLength = [:]
        self.validWordSet = Set(puzzle.validWords)
        self.completedLengths = []
        self.sweepBonus = 0
        self.lengthBonusTotal = 0
        self.foundPangramCount = 0
        self.lastSubmissionBonusEvents = []
        self.pendingCelebrations = []
        self.isShuffling = false
        self.roundPhase = .playing
    }

    /// D-10: the round ends only here, on the manual "Finish Round" tap.
    /// Records the session BEFORE flipping phase so the missed-words screen renders
    /// against already-persisted data (CONTEXT discretion: simplest to test).
    func finishRound() {
        guard roundPhase == .playing else { return }
        // Phase 9 D-11/D-13: the new lifetime stats are written once, at Finish Round only.
        persistenceStore?.record(score: score, wordsFoundCount: foundWords.count,
                                 rank: rank, pangramsFound: foundPangramCount, hadSweep: sweepBonus > 0)
        roundPhase = .roundOver
    }

    // MARK: - Word building
    func append(_ letter: Character) {
        guard roundPhase == .playing else { return }
        currentWord.append(letter)
    }

    /// D-05: Delete button removes the last letter.
    func deleteLast() {
        guard !currentWord.isEmpty else { return }
        currentWord.removeLast()
    }

    /// D-05: tapping the assembled word clears it entirely.
    func clearCurrentWord() {
        currentWord = ""
    }

    // MARK: - Submission (D-06 swipe-down triggers this)
    @discardableResult
    func submitCurrentWord() -> Bool {
        guard roundPhase == .playing, let puzzle else { return false }
        let word = currentWord.lowercased()
        currentWord = ""

        // Mirrors PuzzleGenerator.isValidPuzzleWord exactly, plus dictionary and duplicate checks.
        // These MUST agree or the UI would reject words the generator counts as valid.
        if word.count < 4 { return reject(.tooShort) }
        if !word.contains(puzzle.centerLetter) { return reject(.missingCenterLetter) }
        if !Set(word).isSubset(of: puzzle.letters) { return reject(.notAWord) }
        if foundWordSet.contains(word) { return reject(.alreadyFound) }
        if !wordList.contains(word) { return reject(.notAWord) }

        foundWordSet.insert(word)
        foundWords.insert(word, at: 0)
        let isPangram = pangramSet.contains(word)
        let points = ScoreCalculator.points(for: word, isPangram: isPangram)
        score += points
        if isPangram { foundPangramCount += 1 }

        var events: [CompletionEvent] = []
        // D-14/D-18: length completion. Only words in puzzle.validWords count toward a length group
        // (a dictionary-valid extra would over-count and fire the bonus early).
        if validWordSet.contains(word) {
            let length = word.count
            let foundOfLength = (foundCountByLength[length] ?? 0) + 1
            foundCountByLength[length] = foundOfLength
            if let total = lengthTotals[length], foundOfLength == total, !completedLengths.contains(length) {
                completedLengths.insert(length)
                let bonus = ScoreCalculator.lengthCompletionBonus(length: length)
                score += bonus
                lengthBonusTotal += bonus
                events.append(.lengthComplete(length: length, bonus: bonus))
            }
        }
        // D-01/D-02: sweep. `isPangram` guard prevents the empty-set case and re-triggers.
        if isPangram, sweepBonus == 0, pangramSet.isSubset(of: foundWordSet) {
            let bonus = ScoreCalculator.sweepBonus(pangramCount: pangramSet.count)
            score += bonus
            sweepBonus = bonus
            let foundOrder = foundWords.reversed().filter { pangramSet.contains($0) }
            events.append(.pangramSweep(bonus: bonus, pangrams: foundOrder))   // D-17: after length
        }
        // All bonus state must be current BEFORE the counter bump GameView reacts to.
        lastSubmissionBonusEvents = events
        pendingCelebrations.append(contentsOf: events)

        lastOutcome = .accepted(word: word, points: points, isPangram: isPangram)
        acceptedSubmissionCount += 1
        return true
    }

    /// GameView drains celebrations one at a time (UI-SPEC 4/5: sequential, never overlapping).
    func dequeueCelebration() -> CompletionEvent? {
        pendingCelebrations.isEmpty ? nil : pendingCelebrations.removeFirst()
    }

    /// Sets the outcome BEFORE bumping the counter: views read `lastOutcome` inside
    /// `onChange(of: rejectedSubmissionCount)`, so it must already be current.
    /// The counter increments for ALL reasons, including `.alreadyFound` (single trigger path).
    private func reject(_ reason: RejectionReason) -> Bool {
        lastOutcome = .rejected(reason)
        rejectedSubmissionCount += 1
        return false
    }

    // MARK: - Shuffle (PUZZ-04 / D-03)
    /// Reorders ONLY the 6 outer letters; the center letter never moves.
    /// Returns true when a shuffle happened. Rejected (false) outside .playing (Phase 10 D-10)
    /// and during the animation (D-13). currentWord is untouched (D-11).
    @discardableResult
    func shuffleOuterLetters() -> Bool {
        guard roundPhase == .playing, outerLetters.count > 1, !isShuffling else { return false }
        var shuffled = outerLetters
        repeat { shuffled.shuffle() } while shuffled == outerLetters
        outerLetters = shuffled
        isShuffling = true
        shuffleCount += 1
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(GameTheme.shuffleDurationMilliseconds))
            self?.isShuffling = false
        }
        return true
    }
}

#if DEBUG
// MARK: - Debug shortcuts (Debug builds only; never compiled into Release / App Store)
// Reaching > 100% by hand takes nearly every word, so these let on-device testing jump
// straight to the interesting moment: the live 100% crossing, length pills and the sweep.
// In this file (not an extension file) because they need the private bonus bookkeeping.
extension GameViewModel {
    /// Hidden while the App Store screenshot UI test is staging a puzzle (it runs a Debug build).
    static var debugShortcutsEnabled: Bool {
        UserDefaults.standard.string(forKey: "ScreenshotPuzzle") == nil
    }

    /// Unfound puzzle words, ordered so the pangram that would complete the sweep comes last:
    /// typing them in order shows length pills first and ends on the sweep.
    var debugRemainingWords: [String] {
        guard let puzzle else { return [] }
        let remaining = puzzle.validWords.filter { !foundWordSet.contains($0) }
        let (pangrams, others) = (remaining.filter { pangramSet.contains($0) }, remaining.filter { !pangramSet.contains($0) })
        return others.sorted { ($0.count, $0) < ($1.count, $1) } + pangrams.sorted()
    }

    /// Finds every word it can while staying at or under 100%, always leaving the
    /// sweep-completing pangram unfound. Finishing the remaining words is then guaranteed to
    /// cross 100% live (the full puzzle plus bonuses always exceeds the max). Celebrations
    /// earned along the way are discarded so the queue doesn't replay a dozen pills.
    func debugSolveToJustUnderMax() {
        guard roundPhase == .playing else { return }
        for word in debugRemainingWords {
            let isPangram = pangramSet.contains(word)
            let completesSweep = isPangram && pangramSet.subtracting(foundWordSet) == [word]
            if completesSweep { continue }
            var gain = ScoreCalculator.points(for: word, isPangram: isPangram)
            if let total = lengthTotals[word.count], (foundCountByLength[word.count] ?? 0) + 1 == total {
                gain += ScoreCalculator.lengthCompletionBonus(length: word.count)
            }
            if score + gain > maxPossibleScore { continue }
            currentWord = word
            submitCurrentWord()
        }
        pendingCelebrations = []
        lastSubmissionBonusEvents = []
    }

    /// Types the next remaining word into the input; swipe down to submit it as normal.
    func debugTypeNextRemainingWord() {
        guard roundPhase == .playing, let next = debugRemainingWords.first else { return }
        currentWord = next
    }
}
#endif
