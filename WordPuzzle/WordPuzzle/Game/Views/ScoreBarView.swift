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

    var body: some View {
        VStack(alignment: .leading, spacing: GameTheme.sm) {
            HStack {
                Text(rank.displayName)
                    .font(GameTheme.headingFont)
                    .foregroundStyle(Color.primary)
                Spacer()
                Text("\(foundCount) of \(totalCount) words")
                    .font(GameTheme.labelFont)
                    .foregroundStyle(Color.secondary)
            }

            ProgressView(value: progress.isFinite ? min(max(progress, 0), 1) : 0)
                .progressViewStyle(.linear)
                .tint(GameTheme.accent)
        }
        .padding(GameTheme.md)
        .background(GameTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Rank \(rank.displayName). \(foundCount) of \(totalCount) words found."))
    }
}

#Preview("Mid round") {
    ScoreBarView(rank: .adept, foundCount: 12, totalCount: 31, progress: 0.18)
        .padding()
}

#Preview("Legend") {
    ScoreBarView(rank: .legend, foundCount: 31, totalCount: 31, progress: 1.0)
        .padding()
}
