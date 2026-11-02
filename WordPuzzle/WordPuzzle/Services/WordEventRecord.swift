import Foundation
import SwiftData

/// One accepted word, dated at the moment it was found (including any length/sweep bonus it
/// triggered). This is what lets "today" stats split a multi-day round by calendar day: a word
/// found after midnight counts toward the new day even though the round started (and will be
/// recorded as a GameRecord) on another day. Insert-only; a brand-new model, so SwiftData's
/// lightweight migration opens existing v1.0.x stores untouched.
@Model
final class WordEventRecord {
    var date: Date
    var points: Int
    /// When the round this word belongs to was started. Lets a puzzle carried over from an
    /// earlier day count as "played today" once words are found in it.
    var roundStartedAt: Date

    init(date: Date = .now, points: Int, roundStartedAt: Date) {
        self.date = date
        self.points = points
        self.roundStartedAt = roundStartedAt
    }
}
