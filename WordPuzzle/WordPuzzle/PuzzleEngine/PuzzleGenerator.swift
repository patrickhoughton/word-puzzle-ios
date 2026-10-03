import Foundation

/// Generates a valid Spelling Bee-style puzzle using a pangram-word-first approach (D-03).
/// Pangram guarantee comes from construction, not validation (D-04).
///
/// - Parameters:
///   - wordList: A loaded WordList with `pangramWords` pre-computed.
///   - maxAttempts: Number of pangram words to try before giving up.
/// - Returns: A Puzzle with >=20 valid words and at least one pangram.
/// - Throws: `GeneratorError.emptyWordList` if the pangram pool is empty.
///           `GeneratorError.exhaustedRetries` if no valid center letter found in maxAttempts.
func generatePuzzle(from wordList: WordList, maxAttempts: Int = 1000) throws -> Puzzle {
    let pangramWords = wordList.pangramWords   // Pitfall 5: precomputed in WordList.load(), not here
    guard !pangramWords.isEmpty else { throw GeneratorError.emptyWordList }
    let wordSet = wordList.words

    for _ in 0..<maxAttempts {
        // Step 1: Pick a random pangram word — its 7 unique letters become the puzzle set (D-03)
        let pangram = pangramWords.randomElement()!
        let letters = Set(pangram)   // Exactly 7 unique characters (guaranteed by pangramWords filter)

        // Step 2: Try each of the 7 letters as the center letter (D-03)
        for center in letters.shuffled() {
            let valid = wordSet.filter { isValidPuzzleWord($0, letters: letters, center: center) }
            if valid.count >= 20 {
                // Step 3: Compute pangram subset — D-04: at least one pangram guaranteed by construction
                let validArray = Array(valid)
                let pangrams = validArray.filter { Set($0) == letters }
                return Puzzle(
                    letters: letters,
                    centerLetter: center,
                    validWords: validArray,
                    pangrams: pangrams
                )
            }
        }
        // All 7 center letters had < 20 valid words — pick a new pangram word
    }

    throw GeneratorError.exhaustedRetries
}

#if DEBUG
/// Builds the puzzle for a `"<pangram>:<center>"` spec (e.g. `"harmony:r"`), applying
/// the same validity rule as `generatePuzzle`. DEBUG-only: used to stage App Store
/// screenshots on a fixed puzzle. Returns nil for a malformed spec.
func stagedPuzzle(spec: String, from wordList: WordList) -> Puzzle? {
    let parts = spec.lowercased().split(separator: ":")
    guard parts.count == 2, parts[1].count == 1, let center = parts[1].first else { return nil }
    let letters = Set(parts[0])
    guard letters.count == 7, letters.contains(center) else { return nil }
    let valid = wordList.words.filter { isValidPuzzleWord($0, letters: letters, center: center) }
    let validArray = Array(valid)
    return Puzzle(
        letters: letters,
        centerLetter: center,
        validWords: validArray,
        pangrams: validArray.filter { Set($0) == letters }
    )
}
#endif

/// Returns true if `word` satisfies all Spelling Bee validity rules (D-05):
/// - At least 4 letters
/// - Contains the center letter
/// - Uses only letters from the 7-letter set
private func isValidPuzzleWord(_ word: String, letters: Set<Character>, center: Character) -> Bool {
    guard word.count >= 4 else { return false }
    guard word.contains(center) else { return false }
    return Set(word).isSubset(of: letters)
}
