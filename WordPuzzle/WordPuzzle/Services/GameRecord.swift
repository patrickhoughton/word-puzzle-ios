import Foundation
import SwiftData

/// One completed game session. CONTEXT D-01: date, score, wordsFoundCount only —
/// full word lists are intentionally NOT stored (re-generatable from PuzzleGenerator).
@Model
final class GameRecord {
    var date: Date
    var score: Int
    var wordsFoundCount: Int

    init(date: Date = .now, score: Int, wordsFoundCount: Int) {
        self.date = date
        self.score = score
        self.wordsFoundCount = wordsFoundCount
    }
}
