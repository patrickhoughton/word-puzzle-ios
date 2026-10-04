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

    // UX-02 / D-03: the sound preference is a single Bool flag, so it uses @AppStorage —
    // the project convention for simple flags (same as dailyCount / puzzleSeed).
    // Deliberately NOT a new @Observable store (RESEARCH "Anti-Patterns to Avoid").
    // Default true: sound on out of the box, discoverable, and mutable in one tap.
    @AppStorage(SoundManager.soundEffectsEnabledKey) private var soundEffectsEnabled = true
    @State private var isShowingSettings = false
    // Phase 7 D-01: the found-words sheet, opened by tapping the score bar.
    @State private var isShowingFoundWords = false
    // UX-03 gap fix: "Finish Round" doesn't fit next to Shuffle/Delete at
    // accessibility Dynamic Type sizes even shrunk to scale factor 0.3 -- an
    // abbreviated label at large sizes is the standard accessible pattern
    // (matches how system apps shorten labels rather than fight the metrics).
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
        // A sheet, not a fullScreenCover: unlike the paywall, Settings is dismissable.
        .sheet(isPresented: $isShowingSettings) {
            SettingsView(
                soundEffectsEnabled: $soundEffectsEnabled,
                onDone: { isShowingSettings = false }
            )
        }
        // Phase 7 D-03/D-04/D-05: a standard modal sheet (board not interactive behind it at
        // either detent), Done button plus system swipe-to-dismiss.
        .sheet(isPresented: $isShowingFoundWords) {
            FoundWordsView(
                groups: viewModel.foundWordGroups,
                rank: viewModel.rank,
                foundCount: viewModel.foundCount,
                totalCount: viewModel.totalWordCount,
                onDone: { isShowingFoundWords = false }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        // UX-02 / D-01. Counter-based triggers, matching WordDisplayView's haptics:
        // a Bool would silently stop firing on two consecutive identical outcomes
        // (RESEARCH Pitfall 3).
        .onChange(of: viewModel.acceptedSubmissionCount) { _, _ in
            guard case let .accepted(_, _, isPangram) = viewModel.lastOutcome else { return }
            SoundManager.shared.play(
                SoundEffect.forSubmission(accepted: true, isPangram: isPangram),
                enabled: soundEffectsEnabled
            )
        }
        .onChange(of: viewModel.rejectedSubmissionCount) { _, _ in
            // Phase 6 D-05: a duplicate ("already found") plays no sound; forRejection returns nil.
            guard case let .rejected(reason) = viewModel.lastOutcome,
                  let effect = SoundEffect.forRejection(reason) else { return }
            SoundManager.shared.play(effect, enabled: soundEffectsEnabled)
        }
        // D-01 groups round end and paywall shown into one sound. forRoundPhase returns
        // nil for .loading/.playing, so entering a round is silent.
        .onChange(of: viewModel.roundPhase) { _, newPhase in
            // Phase 7: never let the found-words sheet survive a round end and reappear next round.
            if newPhase != .playing { isShowingFoundWords = false }
            guard let effect = SoundEffect.forRoundPhase(newPhase) else { return }
            SoundManager.shared.play(effect, enabled: soundEffectsEnabled)
        }
    }

    private var playingLayout: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    isShowingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(GameTheme.headingFont)
                        .foregroundStyle(Color.secondary)
                        .frame(minWidth: GameTheme.minTapTarget, minHeight: GameTheme.minTapTarget)
                }
                .contentShape(Rectangle())
                .accessibilityLabel(Text(SettingsView.settingsEntryAccessibilityLabel))
            }
            .padding(.horizontal, GameTheme.lg)
            .padding(.top, GameTheme.sm)

            // Phase 7 D-01/D-16: the whole score bar is the tap target, available at all times
            // during .playing (including before any word is found).
            Button {
                isShowingFoundWords = true
            } label: {
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
            }
            .buttonStyle(ScoreBarButtonStyle())
            .accessibilityHint(Text(FoundWordsView.scoreBarAccessibilityHint))
            .padding(.horizontal, GameTheme.lg)
            .padding(.top, GameTheme.sm)

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

    // UX-03 gap fix: at accessibility Dynamic Type sizes, Finish Round moves to
    // its own full-width row below Shuffle/Delete instead of sharing a single
    // HStack row where "Finish Round" doesn't fit even shrunk to scale factor 0.3.
    // Now that ScoreBarView and WordDisplayView shrink-to-fit rather than grow,
    // this one extra row fits without pushing content off the bottom of the screen.
    private var controlRow: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: GameTheme.sm) {
                    iconButtonsRow
                    finishRoundButton
                        .frame(maxWidth: .infinity)
                }
            } else {
                HStack(spacing: GameTheme.md) {
                    iconButtonsRow
                    Spacer()
                    finishRoundButton
                }
            }
        }
    }

    private var iconButtonsRow: some View {
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
        }
    }

    // D-10: the round ends ONLY here. No timer, no auto-end when all words are found.
    private var finishRoundButton: some View {
        Button {
            viewModel.finishRound()
        } label: {
            Text("Finish Round")
                .font(GameTheme.bodyFont)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(minHeight: GameTheme.minTapTarget)
                .padding(.horizontal, GameTheme.md)
        }
        .buttonStyle(.borderedProminent)
    }
}
