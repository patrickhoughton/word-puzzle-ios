import Foundation

/// Phase 8: one bonus the view-model awarded on an accepted submission. Order in a queue is
/// meaningful (D-17: lengthComplete BEFORE pangramSweep for the same word).
enum CompletionEvent: Equatable {
    /// D-14/D-16: every word of `length` found; `bonus` == ScoreCalculator.lengthCompletionBonus(length:).
    case lengthComplete(length: Int, bonus: Int)
    /// D-01/D-08: every pangram found; `pangrams` in the order the player found them (oldest first),
    /// used by the tally to flash each word in turn.
    case pangramSweep(bonus: Int, pangrams: [String])
}

/// Phase 8 frozen copy (08-UI-SPEC Copywriting Contract) and pure tally timing math (D-08).
/// Pure functions so they are unit-testable; views and GameView only read these.
enum CompletionCelebration {
    static func bonusText(_ bonus: Int) -> String { "+\(bonus)" }
    /// D-09 exact.
    static func sweepHeadline(bonus: Int) -> String { "Pangram sweep! \(bonusText(bonus))" }
    static func lengthPillLabel(length: Int) -> String { "\(length) Letters complete!" }
    /// D-16 exact: "<L> Letters complete! +<L>".
    static func lengthPillText(length: Int, bonus: Int) -> String { "\(lengthPillLabel(length: length)) \(bonusText(bonus))" }
    static func sweepAnnouncement(bonus: Int) -> String { "Pangram sweep! plus \(bonus) points" }
    static func lengthAnnouncement(length: Int, bonus: Int) -> String { "\(length) letters complete, plus \(bonus) points" }

    /// D-08: clamp(1.2 / N, 0.03, 0.3) seconds per pangram step.
    static func sweepStepDuration(pangramCount n: Int) -> Double {
        guard n > 0 else { return 0 }
        return min(GameTheme.sweepStepMaxSeconds,
                   max(GameTheme.sweepStepMinSeconds, GameTheme.sweepTallyMaxSeconds / Double(n)))
    }
    /// UI-SPEC 4: individual words only when a step lasts >= 0.08s (N <= 15).
    static func sweepShowsWords(pangramCount n: Int) -> Bool {
        sweepStepDuration(pangramCount: n) >= GameTheme.sweepWordVisibleMinStepSeconds - 1e-9
    }
    /// UI-SPEC 4: at most 12 ticks; for N > 12 tick every ceil(N/12)-th step.
    static func tickInterval(pangramCount n: Int) -> Int {
        max(1, Int((Double(n) / Double(GameTheme.sweepMaxTicks)).rounded(.up)))
    }
    /// `step` is 1-based.
    static func shouldTick(step: Int, pangramCount n: Int) -> Bool {
        step > 0 && step % tickInterval(pangramCount: n) == 0
    }
    static func tickCount(pangramCount n: Int) -> Int {
        (1...max(1, n)).filter { shouldTick(step: $0, pangramCount: n) }.count
    }
    /// Running counter shown on the tally card after `step` pangrams: +7, +14, +21...
    static func tallyValue(step: Int) -> Int { ScoreCalculator.sweepBonus(pangramCount: step) }
}
