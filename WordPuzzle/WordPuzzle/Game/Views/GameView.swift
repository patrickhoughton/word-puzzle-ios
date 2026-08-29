import SwiftUI

/// The Phase 3 game screen. This is the ONLY view that touches GameViewModel —
/// every child is a value-in/closure-out presentation component.
///
/// Layout order top to bottom (03-UI-SPEC.md Spacing Scale usage map):
///   ScoreBar -> WordDisplay -> hex grid -> control row (Shuffle / Delete / Finish)
struct GameView: View {
    @Environment(GameViewModel.self) private var viewModel

    var body: some View {
        ZStack {
            GameTheme.dominant.ignoresSafeArea()

            switch viewModel.roundPhase {
            case .loading:
                ProgressView("Loading words...")
                    .font(GameTheme.bodyFont)
            case .playing, .roundOver:
                playingLayout
            }
        }
        // D-12: the missed-words reveal covers the screen; dismissing it
        // immediately generates the next puzzle. No start screen exists.
        .fullScreenCover(isPresented: .constant(viewModel.roundPhase == .roundOver)) {
            MissedWordsView(
                groups: viewModel.missedWordGroups,
                pangrams: viewModel.pangramSet,
                rank: viewModel.rank,
                foundCount: viewModel.foundCount,
                totalCount: viewModel.totalWordCount,
                onContinue: { viewModel.startNewRound() }
            )
        }
    }

    private var playingLayout: some View {
        VStack(spacing: 0) {
            ScoreBarView(
                rank: viewModel.rank,
                foundCount: viewModel.foundCount,
                totalCount: viewModel.totalWordCount,
                progress: viewModel.progressFraction
            )
            .padding(.horizontal, GameTheme.lg)
            .padding(.top, GameTheme.lg)

            Spacer(minLength: GameTheme.md)

            WordDisplayView(
                word: viewModel.currentWord,
                outcome: viewModel.lastOutcome,
                acceptedCount: viewModel.acceptedSubmissionCount,
                rejectedCount: viewModel.rejectedSubmissionCount,
                onClear: { viewModel.clearCurrentWord() },
                onSubmit: { viewModel.submitCurrentWord() }
            )
            .padding(.horizontal, GameTheme.lg)

            Spacer(minLength: GameTheme.xxl)

            LetterGridView(
                centerLetter: viewModel.centerLetter,
                outerLetters: viewModel.outerLetters,
                isInputDisabled: viewModel.isShuffling,
                onLetterTouched: { viewModel.append($0) }
            )

            Spacer(minLength: GameTheme.xl)

            controlRow
                .padding(.horizontal, GameTheme.lg)
                .padding(.bottom, GameTheme.lg)
        }
    }

    private var controlRow: some View {
        HStack(spacing: GameTheme.md) {
            Button {
                viewModel.shuffleOuterLetters()
            } label: {
                Image(systemName: "shuffle")
                    .font(GameTheme.headingFont)
                    .frame(minWidth: GameTheme.minTapTarget, minHeight: GameTheme.minTapTarget)
            }
            .accessibilityLabel(Text("Shuffle Letters"))

            Button {
                viewModel.deleteLast()
            } label: {
                Image(systemName: "delete.left")
                    .font(GameTheme.headingFont)
                    .frame(minWidth: GameTheme.minTapTarget, minHeight: GameTheme.minTapTarget)
            }
            .accessibilityLabel(Text("Delete Last Letter"))

            Spacer()

            // D-10: the round ends ONLY here. No timer, no auto-end when all
            // words are found.
            Button {
                viewModel.finishRound()
            } label: {
                Text("Finish Round")
                    .font(GameTheme.bodyFont)
                    .frame(minHeight: GameTheme.minTapTarget)
                    .padding(.horizontal, GameTheme.md)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
