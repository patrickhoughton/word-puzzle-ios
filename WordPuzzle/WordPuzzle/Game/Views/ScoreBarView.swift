import SwiftUI

/// GAME-03 / D-09: progress is shown as an original rank TIER plus a found-word
/// count — never as a bare score number.
/// Presentation-only: takes values, no view-model reference.
struct ScoreBarView: View {
    let rank: RankTier
    let foundCount: Int
    let totalCount: Int
    /// 0...1 — score divided by the puzzle's max possible score.
    let progress: Double
    /// D-03/D-04: free puzzles left today, or nil for premium users (nothing renders).
    /// Passed in rather than read from the environment — this view has zero
    /// GameViewModel/store coupling by design (Phase 3 decision).
    let freePuzzlesRemaining: Int?
    /// The daily allowance the remaining count is out of. Passed in (as
    /// `GameViewModel.freePuzzlesPerDay`) so the literal 3 lives in exactly one place.
    let freePuzzlesPerDay: Int

    var body: some View {
        VStack(alignment: .leading, spacing: GameTheme.sm) {
            // UX-03 gap fix: shrink-to-fit on one line at accessibility Dynamic
            // Type sizes instead of truncating ("Novi...", "0 of 7...") or
            // wrapping, which would grow this row's height and risk pushing the
            // control row off the bottom of the screen (no ScrollView here).
            HStack {
                Text(rank.displayName)
                    .font(GameTheme.headingFont)
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Spacer()
                Text("\(foundCount) of \(totalCount) words")
                    .font(GameTheme.labelFont)
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }

            if let freePuzzlesRemaining {
                Text("\(freePuzzlesRemaining) of \(freePuzzlesPerDay) free puzzles today")
                    .font(GameTheme.labelFont)
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            ProgressView(value: progress.isFinite ? min(max(progress, 0), 1) : 0)
                .progressViewStyle(.linear)
                .tint(GameTheme.accent)
        }
        .padding(GameTheme.md)
        .background(GameTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(accessibilityText))
    }

    private var accessibilityText: String {
        var text = "Rank \(rank.displayName). \(foundCount) of \(totalCount) words found."
        if let freePuzzlesRemaining {
            text += " \(freePuzzlesRemaining) of \(freePuzzlesPerDay) free puzzles remaining today."
        }
        return text
    }
}

#Preview("Mid round") {
    ScoreBarView(
        rank: .adept,
        foundCount: 12,
        totalCount: 31,
        progress: 0.18,
        freePuzzlesRemaining: nil,
        freePuzzlesPerDay: 3
    )
    .padding()
}

#Preview("Legend") {
    ScoreBarView(
        rank: .legend,
        foundCount: 31,
        totalCount: 31,
        progress: 1.0,
        freePuzzlesRemaining: nil,
        freePuzzlesPerDay: 3
    )
    .padding()
}

#Preview("Free user, 2 puzzles left") {
    ScoreBarView(
        rank: .adept,
        foundCount: 12,
        totalCount: 31,
        progress: 0.18,
        freePuzzlesRemaining: 2,
        freePuzzlesPerDay: 3
    )
    .padding()
}
