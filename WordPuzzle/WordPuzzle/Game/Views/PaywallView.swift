import SwiftUI

/// MON-01 / D-05..D-09: the free-tier dead-end. No dismiss, no game screen behind it —
/// the only actions are Unlock and Restore Purchases.
///
/// Value-in/closure-out, matching MissedWordsView and ScoreBarView: this view NEVER
/// reads EntitlementStore or PersistenceStore from @Environment (04-UI-SPEC.md
/// constraint). It owns only transient UI state (in-flight spinners, inline errors).
struct PaywallView: View {
    /// `entitlementStore.unlimitedProduct?.displayPrice`, resolved by the caller.
    /// "—" when StoreKit has not resolved the product yet (D-08).
    let priceText: String
    /// Local midnight, from `PersistenceStore.nextResetDate()`. NEVER recomputed here —
    /// RESEARCH Pitfall 4: a rolling-24h offset would disagree with the daily count.
    let resetDate: Date
    let puzzlesPlayedToday: Int
    let currentStreak: Int
    let todayScore: Int
    let todayWordsFound: Int
    /// Throws on purchase failure. On success the caller leaves this screen.
    let onUnlock: () async throws -> Void
    /// Returns true when premium was actually restored; throws on StoreKit failure.
    let onRestore: () async throws -> Bool

    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var purchaseError: String?
    @State private var restoreError: String?

    /// D-06 format contract (04-UI-SPEC.md Copywriting Contract):
    /// >= 1h -> "{H}h {M}m"; < 1h -> "{M}m"; < 60s -> "Less than a minute".
    /// `static` so the format rules are unit-testable without rendering the view.
    static func countdownText(remaining: TimeInterval) -> String {
        let seconds = max(0, remaining)
        if seconds < 60 { return "Less than a minute" }
        let totalMinutes = Int(seconds) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours >= 1 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }

    var body: some View {
        // ScrollView so the screen degrades gracefully on an iPhone SE instead of clipping.
        ScrollView {
            VStack(spacing: GameTheme.xl) {
                countdownBlock
                statsCard
                ctaBlock
            }
            .padding(.horizontal, GameTheme.lg)
            .padding(.bottom, GameTheme.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GameTheme.dominant)
        // D-05: a true dead-end. There is no dismiss affordance anywhere on this screen.
        .interactiveDismissDisabled()
    }

    // MARK: - Countdown (D-06)

    private var countdownBlock: some View {
        VStack(spacing: GameTheme.sm) {
            Text("Next free puzzle in")
                .font(GameTheme.labelFont)
                .foregroundStyle(Color.secondary)

            // TimelineView, not Timer.scheduledTimer: SwiftUI-native, no manual
            // invalidation, no retained-timer leak. `context.date` (not Date()) avoids drift.
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(Self.countdownText(remaining: resetDate.timeIntervalSince(context.date)))
                    .font(GameTheme.displayFont)
                    .foregroundStyle(GameTheme.accent)
                    .monospacedDigit()
            }
        }
        .padding(.top, GameTheme.xxl)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Today's stats (D-07)

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: GameTheme.sm) {
            Text("Today's Stats")
                .font(GameTheme.headingFont)
                .foregroundStyle(Color.primary)

            statRow(caption: "Puzzles today", value: "\(puzzlesPlayedToday)")
            statRow(caption: "Streak", value: "\(currentStreak)")
            statRow(caption: "Score", value: "\(todayScore)")
            statRow(caption: "Words found", value: "\(todayWordsFound)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GameTheme.md)
        .background(GameTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 12))
    }

    /// All four values render even at 0 — a day of only abandoned rounds (D-02) is
    /// valid content, not an empty state.
    private func statRow(caption: String, value: String) -> some View {
        HStack {
            Text(caption)
                .font(GameTheme.labelFont)
                .foregroundStyle(Color.secondary)
            Spacer()
            Text(value)
                .font(GameTheme.bodyFont)
                .foregroundStyle(Color.primary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(caption): \(value)"))
    }

    // MARK: - CTA (D-08 / D-09)

    private var ctaBlock: some View {
        VStack(spacing: GameTheme.md) {
            // D-08: the price is prominent and literal — no value-framed copy.
            Text(priceText)
                .font(GameTheme.headingFont)
                .foregroundStyle(GameTheme.accent)

            Button {
                Task { await unlock() }
            } label: {
                Group {
                    if isPurchasing {
                        ProgressView()
                    } else {
                        Text("Unlock Unlimited Puzzles")
                            .font(GameTheme.bodyFont)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: GameTheme.minTapTarget)
            }
            .buttonStyle(.borderedProminent)
            .tint(GameTheme.accent)
            .disabled(isPurchasing || isRestoring)

            if let purchaseError {
                Text(purchaseError)
                    .font(GameTheme.bodyFont)
                    .foregroundStyle(GameTheme.errorColor)
                    .multilineTextAlignment(.center)
            }

            // D-09 / Guideline 3.1.1: visible and functional, but a secondary text link
            // that does not compete with the primary CTA — never accent-tinted.
            Button {
                Task { await restorePurchases() }
            } label: {
                Group {
                    if isRestoring {
                        ProgressView()
                    } else {
                        Text("Restore Purchases")
                            .font(GameTheme.labelFont)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: GameTheme.minTapTarget)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.secondary)
            .disabled(isPurchasing || isRestoring)

            if let restoreError {
                Text(restoreError)
                    .font(GameTheme.bodyFont)
                    .foregroundStyle(GameTheme.errorColor)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Actions

    private func unlock() async {
        purchaseError = nil
        restoreError = nil
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            try await onUnlock()
        } catch {
            purchaseError = "Purchase failed. Check your connection and try again."
        }
    }

    private func restorePurchases() async {
        purchaseError = nil
        restoreError = nil
        isRestoring = true
        defer { isRestoring = false }
        do {
            let restored = try await onRestore()
            if !restored {
                restoreError = "No previous purchase found for this Apple ID."
            }
        } catch {
            restoreError = "No previous purchase found for this Apple ID."
        }
    }
}

#Preview("Free user at the daily limit") {
    PaywallView(
        priceText: "$2.99",
        resetDate: Calendar.current.date(byAdding: .hour, value: 2, to: .now)!,
        puzzlesPlayedToday: 3,
        currentStreak: 5,
        todayScore: 148,
        todayWordsFound: 37,
        onUnlock: {},
        onRestore: { true }
    )
}

#Preview("All of today's rounds abandoned") {
    PaywallView(
        priceText: "$2.99",
        resetDate: Calendar.current.date(byAdding: .minute, value: 40, to: .now)!,
        puzzlesPlayedToday: 3,
        currentStreak: 0,
        todayScore: 0,
        todayWordsFound: 0,
        onUnlock: {},
        onRestore: { false }
    )
}
