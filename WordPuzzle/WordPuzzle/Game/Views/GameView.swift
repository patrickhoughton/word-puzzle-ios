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
    // Phase 9 D-02: top-bar stats sheet. A SEPARATE flag drives the round-over stats sheet,
    // because a sheet on GameView's root cannot present while the fullScreenCover is up
    // (RESEARCH Pitfall 2); the two flags never fight.
    @State private var isShowingStats = false
    @State private var isShowingRoundOverStats = false
    // UX-03 gap fix: "Finish Round" doesn't fit next to Shuffle/Delete at
    // accessibility Dynamic Type sizes even shrunk to scale factor 0.3 -- an
    // abbreviated label at large sizes is the standard accessible pattern
    // (matches how system apps shorten labels rather than fight the metrics).
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    // Phase 8: celebration overlay state. Driven only by the drain Task below (RESEARCH Pattern 3).
    @State private var activeCelebration: CompletionEvent?
    @State private var sweepStep = 0
    @State private var sweepIsFinal = false
    @State private var celebrationTask: Task<Void, Never>?
    // Counter-based haptic triggers (Phase 3 Pitfall 3), bumped by the drain at the visual moment,
    // NOT at submission, so they never coincide with WordDisplayView's per-word .success.
    @State private var lengthHapticCount = 0
    @State private var sweepHapticCount = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
                    onContinue: { viewModel.requestNextRound(isPremium: entitlementStore.isPremium) },
                    sweepBonus: viewModel.sweepBonus,
                    lengthBonusTotal: viewModel.lengthBonusTotal,
                    // D-04: read at render time; finishRound() recorded the round BEFORE flipping
                    // to .roundOver, so these include the round just played.
                    bestScore: persistenceStore.bestScore(),
                    currentStreak: persistenceStore.currentStreak(),
                    onShowStats: {
                        isShowingRoundOverStats = true
                    }
                )
                // RESEARCH Pitfall 2: attached INSIDE the cover so it presents on top of it;
                // dismissing returns to the round-over screen (UI-SPEC).
                .sheet(isPresented: $isShowingRoundOverStats) {
                    NavigationStack {
                        StatsView(stats: freshStats, showsDoneButton: true,
                                  onDone: { isShowingRoundOverStats = false })
                    }
                }
            }
        }
        // A sheet, not a fullScreenCover: unlike the paywall, Settings is dismissable.
        .sheet(isPresented: $isShowingSettings) {
            SettingsView(
                soundEffectsEnabled: $soundEffectsEnabled,
                onDone: { isShowingSettings = false },
                stats: freshStats
            )
        }
        // Phase 9 D-02: full-height sheet (no detents), Done + swipe-to-dismiss, same as Settings.
        .sheet(isPresented: $isShowingStats) {
            NavigationStack {
                StatsView(stats: freshStats, showsDoneButton: true, onDone: { isShowingStats = false })
            }
        }
        // Phase 7 D-03/D-04/D-05: a standard modal sheet (board not interactive behind it at
        // either detent), Done button plus system swipe-to-dismiss.
        .sheet(isPresented: $isShowingFoundWords) {
            FoundWordsView(
                groups: viewModel.foundWordGroups,
                rank: viewModel.rank,
                foundCount: viewModel.foundCount,
                totalCount: viewModel.totalWordCount,
                onDone: { isShowingFoundWords = false },
                foundPangrams: viewModel.foundPangramCount,
                totalPangrams: viewModel.totalPangramCount
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        // UX-02 / D-01. Counter-based triggers, matching WordDisplayView's haptics:
        // a Bool would silently stop firing on two consecutive identical outcomes
        // (RESEARCH Pitfall 3).
        .onChange(of: viewModel.acceptedSubmissionCount) { _, _ in
            guard case let .accepted(_, _, isPangram) = viewModel.lastOutcome else { return }
            let earnedBonus = !viewModel.lastSubmissionBonusEvents.isEmpty
            // UI-SPEC 5: a celebration's own sound replaces the per-word sound (no double-play).
            if let effect = SoundEffect.forAcceptedSubmission(isPangram: isPangram, earnedBonus: earnedBonus) {
                SoundManager.shared.play(effect, enabled: soundEffectsEnabled)
            }
            if earnedBonus { startCelebrationDrainIfNeeded() }
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
            // Phase 9: never let a stats sheet outlive its context.
            if newPhase != .playing { isShowingStats = false }
            if newPhase != .roundOver { isShowingRoundOverStats = false }
            // Phase 7: never let the found-words sheet survive a round end and reappear next round.
            if newPhase != .playing {
                isShowingFoundWords = false
                cancelCelebrations()
            }
            guard let effect = SoundEffect.forRoundPhase(newPhase) else { return }
            SoundManager.shared.play(effect, enabled: soundEffectsEnabled)
        }
        .sensoryFeedback(.success, trigger: lengthHapticCount)
        .sensoryFeedback(.success, trigger: sweepHapticCount)
    }

    // RESEARCH Pitfall 4: every stats surface reads the store inside its sheet content, so it is
    // fresh each time it opens. A @State snapshot set in the same tap that flips the sheet flag
    // reached the sheet stale (.empty) on device -- 09-06 found all-zero stats that way.
    private var freshStats: PlayerStats { persistenceStore.playerStats() }

    @ViewBuilder private var celebrationOverlay: some View {
        switch activeCelebration {
        case let .lengthComplete(length, bonus):
            LengthCompletePill(length: length, bonus: bonus)
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(y: -GameTheme.lengthPillSlideOffset)))
        case let .pangramSweep(bonus, pangrams):
            SweepTallyCard(bonus: bonus, pangrams: pangrams, step: sweepStep, isFinal: sweepIsFinal,
                           showsWords: CompletionCelebration.sweepShowsWords(pangramCount: pangrams.count))
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: GameTheme.sweepCardInScale)))
        case nil:
            EmptyView()
        }
    }

    // MARK: - Phase 8 celebration drain (sequential, one cancellable Task)

    private func startCelebrationDrainIfNeeded() {
        guard celebrationTask == nil else { return }   // a running drain picks up newly queued events
        celebrationTask = Task { @MainActor in
            await pause(GameTheme.celebrationLeadInSeconds)
            while !Task.isCancelled, let event = viewModel.dequeueCelebration() {
                switch event {
                case let .lengthComplete(length, bonus): await playLengthCelebration(length: length, bonus: bonus)
                case let .pangramSweep(bonus, pangrams): await playSweepCelebration(bonus: bonus, pangrams: pangrams)
                }
            }
            // Only the live drain clears state: a cancelled drain must not nil out a newer drain's handle.
            guard !Task.isCancelled else { return }
            activeCelebration = nil
            celebrationTask = nil
        }
    }

    private func cancelCelebrations() {
        celebrationTask?.cancel()
        celebrationTask = nil
        activeCelebration = nil
        sweepStep = 0
        sweepIsFinal = false
    }

    private func pause(_ seconds: Double) async { try? await Task.sleep(for: .seconds(seconds)) }

    private func announce(_ text: String) { AccessibilityNotification.Announcement(text).post() }

    private func playLengthCelebration(length: Int, bonus: Int) async {
        withAnimation(.easeOut(duration: reduceMotion ? GameTheme.reduceMotionCrossfadeSeconds : GameTheme.lengthPillInSeconds)) {
            activeCelebration = .lengthComplete(length: length, bonus: bonus)
        }
        SoundManager.shared.play(.lengthComplete, enabled: soundEffectsEnabled)
        lengthHapticCount += 1
        announce(CompletionCelebration.lengthAnnouncement(length: length, bonus: bonus))
        await pause(GameTheme.lengthPillInSeconds + GameTheme.lengthPillHoldSeconds)
        guard !Task.isCancelled else { return }
        withAnimation(.easeIn(duration: GameTheme.celebrationFadeOutSeconds)) { activeCelebration = nil }
        await pause(GameTheme.celebrationFadeOutSeconds)
    }

    private func playSweepCelebration(bonus: Int, pangrams: [String]) async {
        let n = pangrams.count
        sweepStep = 0
        if reduceMotion {
            // No scale, no per-step animation, no ticks; single fanfare + haptic.
            sweepIsFinal = true
            withAnimation(.easeInOut(duration: GameTheme.reduceMotionCrossfadeSeconds)) {
                activeCelebration = .pangramSweep(bonus: bonus, pangrams: pangrams)
            }
            finishSweep(bonus: bonus)
            await pause(GameTheme.reduceMotionCrossfadeSeconds + GameTheme.reduceMotionHoldSeconds)
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: GameTheme.reduceMotionCrossfadeSeconds)) { activeCelebration = nil }
            await pause(GameTheme.reduceMotionCrossfadeSeconds)
            return
        }
        sweepIsFinal = false
        withAnimation(GameTheme.sweepCardAnimation) {
            activeCelebration = .pangramSweep(bonus: bonus, pangrams: pangrams)
        }
        await pause(GameTheme.sweepCardInSeconds)
        let stepDuration = CompletionCelebration.sweepStepDuration(pangramCount: n)
        for step in 1...max(1, n) {
            guard !Task.isCancelled else { return }
            withAnimation(.default) { sweepStep = step }
            if CompletionCelebration.shouldTick(step: step, pangramCount: n) {
                SoundManager.shared.play(.sweepTick, enabled: soundEffectsEnabled)
            }
            await pause(stepDuration)
        }
        guard !Task.isCancelled else { return }
        withAnimation(.default) { sweepIsFinal = true }
        finishSweep(bonus: bonus)
        await pause(GameTheme.sweepHeadlineHoldSeconds)
        guard !Task.isCancelled else { return }
        withAnimation(.easeIn(duration: GameTheme.celebrationFadeOutSeconds)) { activeCelebration = nil }
        await pause(GameTheme.celebrationFadeOutSeconds)
    }

    private func finishSweep(bonus: Int) {
        SoundManager.shared.play(.pangramSweep, enabled: soundEffectsEnabled)   // D-10 fanfare on the final frame
        sweepHapticCount += 1
        announce(CompletionCelebration.sweepAnnouncement(bonus: bonus))
    }

    private var playingLayout: some View {
        VStack(spacing: 0) {
            HStack(spacing: GameTheme.sm) {
                Button {
                    isShowingStats = true
                } label: {
                    Image(systemName: "chart.bar.fill")
                        .font(GameTheme.headingFont)
                        .foregroundStyle(Color.secondary)
                        .frame(minWidth: GameTheme.minTapTarget, minHeight: GameTheme.minTapTarget)
                }
                .contentShape(Rectangle())
                .accessibilityLabel(Text(StatsView.entryAccessibilityLabel))
                .accessibilityIdentifier("topBarStatsButton")
                #if DEBUG
                if GameViewModel.debugShortcutsEnabled {
                    Menu {
                        Button("Solve to just under 100%") { viewModel.debugSolveToJustUnderMax() }
                        Button("Type next missing word (\(viewModel.debugRemainingWords.count) left)") {
                            viewModel.debugTypeNextRemainingWord()
                        }
                    } label: {
                        Image(systemName: "ladybug")
                            .font(GameTheme.headingFont)
                            .foregroundStyle(Color.secondary)
                            .frame(minWidth: GameTheme.minTapTarget, minHeight: GameTheme.minTapTarget)
                    }
                    .accessibilityLabel(Text("Debug shortcuts"))
                }
                #endif
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
                    freePuzzlesPerDay: GameViewModel.freePuzzlesPerDay,
                    foundPangrams: viewModel.foundPangramCount,
                    totalPangrams: viewModel.totalPangramCount
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
            .overlay(alignment: .top) {
                celebrationOverlay
                    .padding(.top, GameTheme.lg)
                    .allowsHitTesting(false)
            }

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
