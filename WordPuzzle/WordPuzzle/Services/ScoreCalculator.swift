import Foundation

/// CONTEXT D-02 (locked): standard Spelling Bee scoring.
///   - 4-letter word          = 1 point
///   - 5-or-more-letter word  = word.count points
///   - pangram                = +7 bonus on top of the length score
/// Words shorter than 4 letters score 0 (Phase 1 D-05 sets the 4-letter floor).
enum ScoreCalculator {

    /// Points awarded for a single submitted word.
    static func points(for word: String, isPangram: Bool) -> Int {
        let length = word.count
        guard length >= 4 else { return 0 }
        let base = (length == 4) ? 1 : length
        return base + (isPangram ? 7 : 0)
    }

    /// Total session score. `pangrams` is the puzzle's pangram list (Puzzle.pangrams)
    /// as a Set for O(1) membership, matching the Phase 1 O(1)-lookup convention.
    static func score(for words: [String], pangrams: Set<String>) -> Int {
        words.reduce(0) { total, word in
            total + points(for: word, isPangram: pangrams.contains(word))
        }
    }
}
