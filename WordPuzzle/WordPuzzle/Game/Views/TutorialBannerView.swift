import SwiftUI

/// Phase 11 UI-SPEC: fixed text banner (chosen over speech bubbles: safest at AX5, never covers tiles).
/// Also renders the Ready card on the final step (D-03). GameView passes everything in.
struct TutorialBannerView: View {
    static let skipLabel = "Skip tutorial"

    /// "Step N of 9"; nil on the Ready card.
    let stepLabel: String?
    let title: String
    let instruction: String
    let compactInstruction: String
    let isReady: Bool
    /// Cap for the accessibility-size scroll container (screen height * GameTheme.tutorialBannerMaxHeightFraction). 0 = no cap.
    let maxHeight: CGFloat
    let onSkip: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// Natural content height at accessibility sizes. A ScrollView has no intrinsic height, so without this it collapses.
    @State private var contentHeight: CGFloat = 0

    static func showsStepLabel(for size: DynamicTypeSize) -> Bool { !size.isAccessibilitySize }
    static func displayedInstruction(full: String, compact: String, size: DynamicTypeSize) -> String {
        size.isAccessibilitySize ? compact : full
    }

    private var textBlock: some View {
        VStack(alignment: .leading, spacing: GameTheme.xs) {
            if Self.showsStepLabel(for: dynamicTypeSize), let stepLabel {
                Text(stepLabel)
                    .font(GameTheme.labelFont)
                    .foregroundStyle(Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(title)
                .font(isReady ? GameTheme.displayFont : GameTheme.headingFont)
                .fixedSize(horizontal: false, vertical: true)
            Text(Self.displayedInstruction(full: instruction, compact: compactInstruction, size: dynamicTypeSize))
                .font(GameTheme.bodyFont)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("tutorialBanner")
        .accessibilityAddTraits(.isHeader)
    }

    private var skipLink: some View {
        Button(Self.skipLabel, action: onSkip)
            .font(GameTheme.labelFont)
            .foregroundStyle(Color.secondary)
            .frame(minHeight: GameTheme.minTapTarget)
            .contentShape(Rectangle())
            .accessibilityIdentifier("tutorialSkipLink")
    }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                // Skip stays pinned below the scrolling text so it is always visible and reachable.
                VStack(alignment: .leading, spacing: GameTheme.sm) {
                    ScrollView(.vertical) {
                        textBlock
                            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .frame(height: maxHeight > 0 ? min(contentHeight, maxHeight) : contentHeight)
                    skipLink.frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(alignment: .leading, spacing: GameTheme.sm) {
                    textBlock.allowsHitTesting(false)
                    HStack {
                        Spacer()
                        skipLink
                    }
                }
            }
        }
        .padding(.horizontal, GameTheme.md)
        .padding(.vertical, GameTheme.sm)
        .background(GameTheme.secondarySurface, in: RoundedRectangle(cornerRadius: GameTheme.celebrationCornerRadius))
    }
}

#Preview("Step") {
    TutorialBannerView(stepLabel: "Step 1 of 9", title: "Build a word",
                       instruction: "Tap the glowing letters to spell POND.",
                       compactInstruction: "Tap the glowing letters.",
                       isReady: false, maxHeight: 0, onSkip: {})
        .padding()
}

#Preview("Ready") {
    TutorialBannerView(stepLabel: nil, title: "Ready?",
                       instruction: "Tap Finish Round when you are done.",
                       compactInstruction: "Tap Finish Round.",
                       isReady: true, maxHeight: 0, onSkip: {})
        .padding()
}
