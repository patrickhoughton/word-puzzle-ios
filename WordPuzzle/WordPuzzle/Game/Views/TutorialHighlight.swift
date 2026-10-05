import SwiftUI

/// Phase 11 UI-SPEC: the pulsing gold ring on the current step's target. Reuses the
/// OverflowGlow pulse so Reduce Motion gets the same steady 0.5 treatment.
/// Purely decorative: never hit-testable and hidden from VoiceOver (the target keeps its own label).
struct TutorialHighlight<S: Shape>: ViewModifier {
    let isActive: Bool
    let shape: S
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay {
            if isActive {
                TimelineView(.animation(paused: reduceMotion)) { timeline in
                    let t = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
                    let pulse = OverflowGlow.pulse(time: t, reduceMotion: reduceMotion)
                    shape
                        .stroke(GameTheme.accent, lineWidth: GameTheme.tutorialHighlightStroke)
                        .shadow(color: GameTheme.accent.opacity(OverflowGlow.opacity(pulse: pulse)),
                                radius: OverflowGlow.radius(pulse: pulse))
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
        }
    }
}

extension View {
    func tutorialHighlight<S: Shape>(_ isActive: Bool, in shape: S) -> some View {
        modifier(TutorialHighlight(isActive: isActive, shape: shape))
    }
}
