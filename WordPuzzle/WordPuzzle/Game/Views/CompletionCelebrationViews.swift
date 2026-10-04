import SwiftUI

/// Phase 8 D-08/D-09 (UI-SPEC 4). GameView advances `step` and flips `isFinal`; this view only renders.
struct SweepTallyCard: View {
    let bonus: Int              // final N (7 x pangram count)
    let pangrams: [String]      // found order
    let step: Int               // 0...pangrams.count
    let isFinal: Bool
    let showsWords: Bool        // CompletionCelebration.sweepShowsWords(pangramCount:)

    var body: some View {
        VStack(spacing: GameTheme.sm) {
            if isFinal {
                Label(CompletionCelebration.sweepHeadline(bonus: bonus), systemImage: "checkmark.seal.fill")
                    .font(GameTheme.headingFont).foregroundStyle(GameTheme.accent)
                    .lineLimit(1).minimumScaleFactor(0.5)
            } else {
                Text(CompletionCelebration.bonusText(CompletionCelebration.tallyValue(step: step)))
                    .font(GameTheme.displayFont).foregroundStyle(GameTheme.accent)
                    .monospacedDigit().contentTransition(.numericText())
                    .lineLimit(1).minimumScaleFactor(0.5)
                if showsWords, step > 0, step <= pangrams.count {
                    Text(pangrams[step - 1].uppercased())
                        .font(GameTheme.bodyFont).foregroundStyle(Color.primary)
                        .lineLimit(1).minimumScaleFactor(0.5)
                }
            }
        }
        .padding(.horizontal, GameTheme.md)
        .padding(.vertical, GameTheme.lg)
        .frame(maxWidth: .infinity)
        .background(GameTheme.secondarySurface, in: RoundedRectangle(cornerRadius: GameTheme.celebrationCornerRadius))
        .shadow(color: .black.opacity(GameTheme.celebrationShadowOpacity), radius: GameTheme.celebrationShadowRadius)
        .allowsHitTesting(false)
        .accessibilityHidden(true)   // VoiceOver gets one announcement instead (UI-SPEC 4)
    }
}

/// Phase 8 D-16 (UI-SPEC 5): "<L> Letters complete! +<L>", label primary, "+L" accent.
struct LengthCompletePill: View {
    let length: Int
    let bonus: Int

    private var attributedLabel: AttributedString {
        var label = AttributedString(CompletionCelebration.lengthPillLabel(length: length) + " ")
        label.foregroundColor = .primary
        var plus = AttributedString(CompletionCelebration.bonusText(bonus))
        plus.foregroundColor = GameTheme.accent
        return label + plus
    }

    var body: some View {
        HStack(spacing: GameTheme.xs) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(GameTheme.accent)
            Text(attributedLabel)
        }
        .font(GameTheme.headingFont)
        .lineLimit(1).minimumScaleFactor(0.5)
        .padding(.vertical, GameTheme.sm)
        .padding(.horizontal, GameTheme.md)
        .background(GameTheme.secondarySurface, in: Capsule())
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#Preview("Sweep tally mid") {
    SweepTallyCard(bonus: 21, pangrams: ["cabined", "abidance", "candles"], step: 2, isFinal: false, showsWords: true)
        .padding()
}

#Preview("Sweep final") {
    SweepTallyCard(bonus: 21, pangrams: ["cabined", "abidance", "candles"], step: 3, isFinal: true, showsWords: true)
        .padding()
}

#Preview("Length pill") {
    LengthCompletePill(length: 5, bonus: 5)
}

#Preview("Celebrations AX5") {
    VStack(spacing: GameTheme.md) {
        SweepTallyCard(bonus: 21, pangrams: ["cabined", "abidance", "candles"], step: 2, isFinal: false, showsWords: true)
        LengthCompletePill(length: 5, bonus: 5)
    }
    .padding()
    .environment(\.dynamicTypeSize, .accessibility5)
}
