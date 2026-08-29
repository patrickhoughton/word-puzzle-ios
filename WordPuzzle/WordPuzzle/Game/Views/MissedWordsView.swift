import SwiftUI

/// GAME-04 / D-11: the round-end reveal. Missed words are grouped by length with
/// any missed pangram specially highlighted — a flat undifferentiated list does
/// NOT satisfy D-11.
///
/// D-12: `onContinue` immediately generates the next puzzle. There is no start
/// screen and no menu in Phase 3.
///
/// Uses ScrollView + LazyVStack, never `List` — CLAUDE.md and 03-UI-SPEC.md both
/// forbid List here (row separators / extra chrome).
struct MissedWordsView: View {
    let groups: [MissedWordGroup]
    let pangrams: Set<String>
    let rank: RankTier
    let foundCount: Int
    let totalCount: Int
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header

            if groups.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: GameTheme.sm) {
                        ForEach(groups) { group in
                            Text("\(group.length) Letters")
                                .font(GameTheme.headingFont)
                                .padding(.top, GameTheme.md)
                                .padding(.horizontal, GameTheme.md)

                            ForEach(group.words, id: \.self) { word in
                                wordRow(word)
                            }
                        }
                    }
                    .padding(.horizontal, GameTheme.lg)
                    .padding(.bottom, GameTheme.lg)
                }
            }

            Button(action: onContinue) {
                Text("Next Puzzle")
                    .font(GameTheme.bodyFont)
                    .frame(maxWidth: .infinity, minHeight: GameTheme.minTapTarget)
            }
            .buttonStyle(.borderedProminent)
            .padding(GameTheme.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GameTheme.dominant)
    }

    private var header: some View {
        VStack(spacing: GameTheme.sm) {
            Text(groups.isEmpty ? "Perfect Round!" : "Words You Missed")
                .font(GameTheme.displayFont)
            Text("\(rank.displayName) — \(foundCount) of \(totalCount) words")
                .font(GameTheme.labelFont)
                .foregroundStyle(Color.secondary)
        }
        .padding(GameTheme.lg)
    }

    private var emptyState: some View {
        VStack(spacing: GameTheme.md) {
            Spacer()
            Text("You found every word. Nothing missed — nice work.")
                .font(GameTheme.bodyFont)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.secondary)
                .padding(.horizontal, GameTheme.lg)
            Spacer()
        }
    }

    private func wordRow(_ word: String) -> some View {
        let isPangram = pangrams.contains(word)
        return HStack(spacing: GameTheme.sm) {
            Text(word)
                .font(GameTheme.bodyFont)
                .foregroundStyle(isPangram ? GameTheme.accent : Color.primary)
            if isPangram {
                Label("Pangram", systemImage: "checkmark.seal.fill")
                    .font(GameTheme.labelFont)
                    .foregroundStyle(GameTheme.accent)
                    .labelStyle(.titleAndIcon)
            }
            Spacer()
        }
        .padding(.vertical, GameTheme.sm)
        .padding(.horizontal, GameTheme.md)
        .background(GameTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(isPangram ? "\(word), pangram" : word))
    }
}

#Preview("With missed words") {
    MissedWordsView(
        groups: [
            MissedWordGroup(length: 4, words: ["cane", "clan"]),
            MissedWordGroup(length: 5, words: ["lance"]),
            MissedWordGroup(length: 7, words: ["candles"])
        ],
        pangrams: ["candles"],
        rank: .adept,
        foundCount: 12,
        totalCount: 16,
        onContinue: {}
    )
}

#Preview("Perfect round") {
    MissedWordsView(
        groups: [],
        pangrams: [],
        rank: .legend,
        foundCount: 31,
        totalCount: 31,
        onContinue: {}
    )
}
