import Foundation

struct Puzzle {
    let letters: Set<Character>
    let centerLetter: Character
    let validWords: [String]
    let pangrams: [String]

    var hasPangram: Bool { !pangrams.isEmpty }
}

enum GeneratorError: Error {
    case exhaustedRetries
    case emptyWordList
}
