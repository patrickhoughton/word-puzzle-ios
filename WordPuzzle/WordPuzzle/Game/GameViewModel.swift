import Foundation
import Observation

/// Result of one word submission. Drives the word-display feedback in WordDisplayView.
enum SubmissionOutcome: Equatable {
    case accepted(word: String, points: Int, isPangram: Bool)
    case rejected
}

/// One length bucket on the missed-words screen (D-11).
struct MissedWordGroup: Identifiable, Equatable {
    let length: Int
    let words: [String]
    var id: Int { length }
}

/// CONTEXT D-01..D-12. Owns ALL round state. Follows the project's established
/// `@Observable final class` service convention (WordList / PersistenceStore / EntitlementStore).
@MainActor
@Observable
final class GameViewModel {

    enum RoundPhase: Equatable { case loading, playing, roundOver }

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

    // MARK: - Feedback state
    private(set) var lastOutcome: SubmissionOutcome?
    /// RESEARCH Pitfall 3: monotonic counters, never re-set Bools — `.sensoryFeedback(_:trigger:)`
    /// fires on CHANGE, so a Bool set to the same value twice would silently stop firing.
    private(set) var acceptedSubmissionCount: Int = 0
    private(set) var rejectedSubmissionCount: Int = 0
    /// RESEARCH Pitfall 2: gates drag input while the shuffle animation interpolates.
    private(set) var isShuffling: Bool = false

    init(wordList: WordList, persistenceStore: PersistenceStore? = nil) {
        self.wordList = wordList
        self.persistenceStore = persistenceStore
    }

    // MARK: - Derived
    var centerLetter: Character { puzzle?.centerLetter ?? " " }
    var foundCount: Int { foundWords.count }
    var totalWordCount: Int { puzzle?.validWords.count ?? 0 }
    var rank: RankTier { RankTier.tier(score: score, maxScore: maxPossibleScore) }
    var progressFraction: Double {
        guard maxPossibleScore > 0 else { return 0 }
        return min(1, Double(score) / Double(maxPossibleScore))
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

    // MARK: - Round lifecycle
    /// D-12: generates the next puzzle and resets all round state.
    func startNewRound() {
        guard wordList.isLoaded, let generated = try? generatePuzzle(from: wordList) else {
            roundPhase = .loading
            return
        }
        startNewRound(with: generated)
    }

    /// Test seam — the deterministic path used by `startNewRound()`.
    func startNewRound(with puzzle: Puzzle) {
        self.puzzle = puzzle
        self.pangramSet = Set(puzzle.pangrams)
        self.maxPossibleScore = ScoreCalculator.score(for: puzzle.validWords, pangrams: pangramSet)
        self.outerLetters = Array(puzzle.letters.subtracting([puzzle.centerLetter])).shuffled()
        self.currentWord = ""
        self.foundWords = []
        self.foundWordSet = []
        self.score = 0
        self.lastOutcome = nil
        self.isShuffling = false
        self.roundPhase = .playing
    }

    /// D-10: the round ends only here, on the manual "Finish Round" tap.
    /// Records the session BEFORE flipping phase so the missed-words screen renders
    /// against already-persisted data (CONTEXT discretion: simplest to test).
    func finishRound() {
        guard roundPhase == .playing else { return }
        persistenceStore?.record(score: score, wordsFoundCount: foundWords.count)
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
        guard word.count >= 4,
              word.contains(puzzle.centerLetter),
              Set(word).isSubset(of: puzzle.letters),
              !foundWordSet.contains(word),
              wordList.contains(word) else {
            lastOutcome = .rejected
            rejectedSubmissionCount += 1
            return false
        }

        foundWordSet.insert(word)
        foundWords.insert(word, at: 0)
        let isPangram = pangramSet.contains(word)
        let points = ScoreCalculator.points(for: word, isPangram: isPangram)
        score += points
        lastOutcome = .accepted(word: word, points: points, isPangram: isPangram)
        acceptedSubmissionCount += 1
        return true
    }

    // MARK: - Shuffle (PUZZ-04 / D-03)
    /// Reorders ONLY the 6 outer letters; the center letter never moves.
    func shuffleOuterLetters() {
        guard outerLetters.count > 1, !isShuffling else { return }
        var shuffled = outerLetters
        repeat { shuffled.shuffle() } while shuffled == outerLetters
        outerLetters = shuffled
        isShuffling = true
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(GameTheme.shuffleDurationMilliseconds))
            self?.isShuffling = false
        }
    }
}
