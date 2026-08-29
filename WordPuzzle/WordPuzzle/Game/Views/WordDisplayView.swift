import SwiftUI

/// The in-progress word display above the hex grid (D-04).
///
/// SUBMISSION IS A SWIPE-DOWN GESTURE ON THIS VIEW (D-06). This was an explicit,
/// deliberate user decision — there is NO Submit button anywhere in Phase 3.
/// Do not add one.
///
/// Presentation-only: takes values, emits closures. It never references the game's view model.
struct WordDisplayView: View {

    /// The word being assembled. Empty string renders the idle placeholder.
    let word: String
    /// Result of the most recent submission, or nil before the first submission.
    let outcome: SubmissionOutcome?
    /// Monotonic counter — increments on every ACCEPTED submission.
    /// RESEARCH Pitfall 3: `.sensoryFeedback` fires on CHANGE, so a re-set Bool
    /// would silently stop firing on consecutive correct words. Must be a counter.
    let acceptedCount: Int
    /// Monotonic counter — increments on every REJECTED submission.
    let rejectedCount: Int
    /// D-05: tapping the assembled word clears it entirely.
    let onClear: () -> Void
    /// D-06: fired when the downward drag passes the submit threshold.
    let onSubmit: () -> Void

    // Claude's discretion (CONTEXT): gesture thresholds and the "armed" visual cue.
    private let armThreshold: CGFloat = 24
    private let submitThreshold: CGFloat = 60
    private let maxDragFollow: CGFloat = 80

    @State private var dragOffset: CGFloat = 0
    @State private var isArmed = false
    @State private var shakeAmount: CGFloat = 0
    @State private var popScale: CGFloat = 1
    @State private var feedbackText: String?
    @State private var feedbackIsError = false

    var body: some View {
        VStack(spacing: GameTheme.xs) {
            // Feedback line: "+N" on accept (accent, Display) or the generic
            // rejection message (systemRed, Body). D-07 / D-08.
            Text(feedbackText ?? " ")
                .font(feedbackIsError ? GameTheme.bodyFont : GameTheme.displayFont)
                .foregroundStyle(feedbackIsError ? GameTheme.errorColor : GameTheme.accent)
                .frame(minHeight: 40)
                .opacity(feedbackText == nil ? 0 : 1)

            Text(word.isEmpty ? "Tap or drag letters" : word.uppercased())
                .font(GameTheme.headingFont)
                .foregroundStyle(word.isEmpty ? Color.secondary : Color.primary)
                .frame(maxWidth: .infinity)
                .padding(GameTheme.md)
                .background(GameTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(GameTheme.accent, lineWidth: isArmed ? 3 : 0)
                )
                .scaleEffect(popScale)
                .offset(x: shakeAmount, y: dragOffset)
                .contentShape(RoundedRectangle(cornerRadius: 12))
                .onTapGesture { onClear() }
                .gesture(submitDragGesture)
                .accessibilityLabel(Text(word.isEmpty ? "No word assembled" : "Assembled word \(word)"))
                .accessibilityHint(Text("Swipe down to submit. Tap to clear."))
        }
        // RET-03: haptic on every accepted word. Counter-based trigger per Pitfall 3.
        .sensoryFeedback(.success, trigger: acceptedCount)
        .sensoryFeedback(.error, trigger: rejectedCount)
        .onChange(of: acceptedCount) { _, _ in showAcceptedFeedback() }
        .onChange(of: rejectedCount) { _, _ in showRejectedFeedback() }
    }

    private var submitDragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                guard !word.isEmpty, value.translation.height > 0 else { return }
                dragOffset = min(value.translation.height, maxDragFollow)
                isArmed = value.translation.height > armThreshold
            }
            .onEnded { value in
                let shouldSubmit = !word.isEmpty && value.translation.height > submitThreshold
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    dragOffset = 0
                    isArmed = false
                }
                if shouldSubmit { onSubmit() }
            }
    }

    // D-08: brief pop + "+N" points.
    private func showAcceptedFeedback() {
        guard case let .accepted(_, points, isPangram) = outcome else { return }
        feedbackIsError = false
        feedbackText = isPangram ? "+\(points)  Pangram!" : "+\(points)"
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { popScale = 1.12 }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { popScale = 1 }
            try? await Task.sleep(for: .milliseconds(700))
            withAnimation(.easeOut(duration: 0.2)) { feedbackText = nil }
        }
    }

    // D-07: shake + generic message. No reason-specific variants in Phase 3.
    private func showRejectedFeedback() {
        feedbackIsError = true
        feedbackText = "Not a valid word"
        withAnimation(.linear(duration: 0.06).repeatCount(5, autoreverses: true)) {
            shakeAmount = 10
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(360))
            withAnimation(.linear(duration: 0.06)) { shakeAmount = 0 }
            try? await Task.sleep(for: .milliseconds(700))
            withAnimation(.easeOut(duration: 0.2)) { feedbackText = nil }
        }
    }
}

#Preview("Idle") {
    WordDisplayView(word: "", outcome: nil, acceptedCount: 0, rejectedCount: 0,
                    onClear: {}, onSubmit: {})
    .padding()
}

#Preview("Typing") {
    WordDisplayView(word: "candle", outcome: nil, acceptedCount: 0, rejectedCount: 0,
                    onClear: {}, onSubmit: {})
    .padding()
}
