import Foundation
import SwiftData

/// CONTEXT D-02: tracks a round START, independent of whether it is ever finished.
/// Deliberately separate from GameRecord (which only ever represents a FINISHED round,
/// backing RET-02's lifetime stats) so the daily-limit count (this model) and the
/// lifetime "games played" count (GameRecord) can never be conflated. Insert-only —
/// nothing ever mutates or deletes a RoundStartRecord.
@Model
final class RoundStartRecord {
    var date: Date

    init(date: Date = .now) {
        self.date = date
    }
}
