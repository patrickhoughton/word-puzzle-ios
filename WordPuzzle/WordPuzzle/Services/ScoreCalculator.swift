import Foundation

/// CONTEXT D-02 (locked): standard Spelling Bee scoring.
///   - 4-letter word          = 1 point
///   - 5-or-more-letter word  = word.count points
///   - pangram                = +7 bonus on top of the length score
/// Words shorter than 4 letters score 0 (Phase 1 D-05 sets the 4-letter floor).
enum ScoreCalculator {

    /// Per-pangram bonus on top of the length score (single source of truth, D-01).
    static let pangramBonusPerWord = 7

    /// D-01/D-02: completing the pangram set awards +7 per pangram in the puzzle
    /// (doubles each pangram's bonus). Never part of maxPossibleScore (D-03).
    static func sweepBonus(pangramCount: Int) -> Int { max(0, pangramCount) * pangramBonusPerWord }

    /// D-14/D-18: finding every word of length L awards +L. Below the 4-letter floor -> 0.
    static func lengthCompletionBonus(length: Int) -> Int { length >= 4 ? length : 0 }

    /// Points awarded for a single submitted word.
    static func points(for word: String, isPangram: Bool) -> Int {
        let length = word.count
        guard length >= 4 else { return 0 }
        let base = (length == 4) ? 1 : length
        return base + (isPangram ? pangramBonusPerWord : 0)
    }

    /// Total session score. `pangrams` is the puzzle's pangram list (Puzzle.pangrams)
    /// as a Set for O(1) membership, matching the Phase 1 O(1)-lookup convention.
    static func score(for words: [String], pangrams: Set<String>) -> Int {
        words.reduce(0) { total, word in
            total + points(for: word, isPangram: pangrams.contains(word))
        }
    }
}
