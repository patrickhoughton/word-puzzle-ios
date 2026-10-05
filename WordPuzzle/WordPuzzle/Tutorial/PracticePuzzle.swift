import Foundation

/// Phase 11 D-04: the fixed, hand-picked practice board. DOLPHIN with center P.
/// Curated literal on purpose: `stagedPuzzle(spec:from:)` is DEBUG-only and the generator
/// would give a large, unfriendly list. Locked by PracticePuzzleTests against enable-clean.txt.
/// Any in-dictionary word that fits the letters is still accepted as an "extra" by
/// GameViewModel.submitCurrentWord(), so this short list never blocks the player.
enum PracticePuzzle {
    static let centerLetter: Character = "p"
    static let letters: Set<Character> = Set("dolphin")

    /// Lengths: 4 x6, 5 x3, 6 x3, 7 x1 (the pangram). Scripted steps 1-6 accept only
    /// POND and PLOD (both length 4), so no length group completes before the pangram step.
    static let validWords: [String] = [
        "hoop", "loop", "plod", "polo", "pond", "pool",
        "hippo", "lipid", "polio",
        "dollop", "pinion", "poplin",
        "dolphin",
    ]
    static let pangrams: [String] = ["dolphin"]

    /// Step 1 (build, not submitted) and step 3 (swipe to submit).
    static let buildWord = "pond"
    /// Step 2 guided miss (D-06): 4 letters so the rejection is .missingCenterLetter, not .tooShort.
    static let missWord = "hold"
    /// Step 4: pre-filled into the word display so Delete and tap-to-clear have letters to act on.
    static let fixPrefill = "polo"
    /// Step 5: no back-to-back repeated letter (LetterGridView ignores re-entering the same tile).
    static let dragWord = "plod"
    /// Step 7.
    static let pangram = "dolphin"

    static var puzzle: Puzzle {
        Puzzle(letters: letters, centerLetter: centerLetter, validWords: validWords, pangrams: pangrams)
    }
}
