import Foundation
import SwiftData

/// One completed game session. CONTEXT D-01 (Phase 2) plus Phase 9 D-11 optional stats fields —
/// additive optionals only, so SwiftData's automatic lightweight migration opens existing on-device stores.
/// Full word lists are intentionally NOT stored (re-generatable from PuzzleGenerator).
@Model
final class GameRecord {
    var date: Date
    var score: Int
    var wordsFoundCount: Int
    /// Phase 9 D-10/D-11: RankTier.rawValue reached at Finish Round. nil = pre-Phase-9 row (D-12).
    var rankRaw: Int?
    /// Phase 9: pangrams found in this (finished) round (D-13). nil = pre-Phase-9 row.
    var pangramsFound: Int?
    /// Phase 9: true when the pangram sweep bonus fired this round (sweepBonus > 0). nil = pre-Phase-9 row.
    var hadSweep: Bool?

    init(date: Date = .now, score: Int, wordsFoundCount: Int,
         rankRaw: Int? = nil, pangramsFound: Int? = nil, hadSweep: Bool? = nil) {
        self.date = date
        self.score = score
        self.wordsFoundCount = wordsFoundCount
        self.rankRaw = rankRaw
        self.pangramsFound = pangramsFound
        self.hadSweep = hadSweep
    }
}
