import StoreKit
import SwiftUI

/// The Phase 3 game screen. This is the ONLY view that touches GameViewModel —
/// every child is a value-in/closure-out presentation component.
///
/// Layout order top to bottom (03-UI-SPEC.md Spacing Scale usage map):
///   ScoreBar -> WordDisplay -> hex grid -> control row (Shuffle / Delete / Finish)
struct GameView: View {
    @Environment(GameViewModel.self) private var viewModel
    @Environment(EntitlementStore.self) private var entitlementStore
    @Environment(PersistenceStore.self) private var persistenceStore

    var body: some View {
        ZStack {
            GameTheme.dominant.ignoresSafeArea()

            switch viewModel.roundPhase {
            case .loading:
                ProgressView("Loading words...")
                    .font(GameTheme.bodyFont)
            case .playing, .roundOver:
                playingLayout
            case .paywalled:
                // D-05: a true dead-end — nothing playable renders behind the paywall.
                EmptyView()
            }
        }
        // D-12: the missed-words reveal covers the screen; continuing asks the gate
        // whether a next puzzle is allowed. D-01: the same cover shows the paywall when
        // the free daily limit is reached (including the .loading -> .paywalled launch path).
        .fullScreenCover(isPresented: .constant(
            viewModel.roundPhase == .roundOver || viewModel.roundPhase == .paywalled
        )) {
            // RESEARCH Pitfall 5: the presented boolean covers BOTH phases, so this
            // content closure MUST branch too. Always rendering MissedWordsView here
            // would silently ship a paywall that never appears.
            if viewModel.roundPhase == .paywalled {
                PaywallView(
                    priceText: entitlementStore.unlimitedProduct?.displayPrice ?? "—",
                    resetDate: persistenceStore.nextResetDate(),
                    puzzlesPlayedToday: persistenceStore.puzzlesPlayedToday(),
                    currentStreak: persistenceStore.currentStreak(),
                    todayScore: persistenceStore.todayTotalScore(),
                    todayWordsFound: persistenceStore.todayTotalWordsFound(),
                    onUnlock: {
                        try await entitlementStore.purchaseUnlimited()
                        // On success the gate re-runs and starts a round, which flips
                        // roundPhase to .playing and dismisses this cover. Without this
                        // the user would pay and stay stuck on the paywall.
                        if entitlementStore.isPremium {
                            viewModel.requestNextRound(isPremium: true)
                        }
                    },
                    onRestore: {
                        try await entitlementStore.restore()
                        guard entitlementStore.isPremium else { return false }
                        viewModel.requestNextRound(isPremium: true)
                        return true
                    }
                )
            } else {
                MissedWordsView(
                    groups: viewModel.missedWordGroups,
                    pangrams: viewModel.pangramSet,
                    rank: viewModel.rank,
                    foundCount: viewModel.foundCount,
                    totalCount: viewModel.totalWordCount,
                    onContinue: { viewModel.requestNextRound(isPremium: entitlementStore.isPremium) }
                )
            }
        }
    }

    private var playingLayout: some View {
        VStack(spacing: 0) {
            ScoreBarView(
                rank: viewModel.rank,
                foundCount: viewModel.foundCount,
                totalCount: viewModel.totalWordCount,
                progress: viewModel.progressFraction,
                // D-03: only free users see the counter; premium gets nil (nothing renders).
                freePuzzlesRemaining: entitlementStore.isPremium
                    ? nil
                    : max(0, GameViewModel.freePuzzlesPerDay - persistenceStore.puzzlesPlayedToday()),
                freePuzzlesPerDay: GameViewModel.freePuzzlesPerDay
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
