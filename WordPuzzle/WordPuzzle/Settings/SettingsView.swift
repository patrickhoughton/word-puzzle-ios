import SwiftUI

/// UX-02 / Phase 5 D-03, partly reversed by Phase 9 D-03: Settings holds the
/// sound-effects toggle plus a "Stats" row that pushes the player stats screen
/// (backlog 999.1, built in Phase 9). A haptics toggle remains deferred.
///
/// Presentation-only: takes a Binding and a closure, holds no stored preference and
/// no environment/store reads. The preference itself is owned by GameView, matching
/// the Phase 3/4 rule that every non-GameView view is value-in/closure-out.
/// Stats arrive as a `PlayerStats` value built by GameView; Settings never reads a store.
struct SettingsView: View {
    /// Frozen copy (05-UI-SPEC.md Copywriting Contract) — pinned as constants so
    /// SettingsViewTests can assert on it, same pattern as PaywallView's strings.
    static let title = "Settings"
    static let soundToggleLabel = "Sound Effects"
    static let doneButtonLabel = "Done"
    static let settingsEntryAccessibilityLabel = "Settings"
    static let statsRowLabel = "Stats"

    @Binding var soundEffectsEnabled: Bool
    let onDone: () -> Void
    var stats: PlayerStats = .empty

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: GameTheme.md) {
                Toggle(Self.soundToggleLabel, isOn: $soundEffectsEnabled)
                    .font(GameTheme.bodyFont)
                    .padding(GameTheme.md)

                NavigationLink {
                    // Pushed inside THIS NavigationStack: system back button; Settings' own Done stays (UI-SPEC).
                    StatsView(stats: stats, showsDoneButton: false)
                } label: {
                    HStack {
                        Text(Self.statsRowLabel)
                            .font(GameTheme.bodyFont)
                            .foregroundStyle(Color.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(GameTheme.labelFont)
                            .foregroundStyle(Color.secondary)
                            .accessibilityHidden(true)
                    }
                    .frame(minHeight: GameTheme.minTapTarget)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(GameTheme.md)
                .accessibilityIdentifier("settingsStatsRow")

                Spacer()
            }
            .padding(.horizontal, GameTheme.lg)
            .padding(.top, GameTheme.xxl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(GameTheme.dominant)
            .navigationTitle(Self.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(Self.doneButtonLabel) { onDone() }
                        .font(GameTheme.bodyFont)
                }
            }
        }
    }
}

#Preview {
    SettingsView(soundEffectsEnabled: .constant(true), onDone: {})
}

#Preview("With stats") {
    SettingsView(soundEffectsEnabled: .constant(true), onDone: {}, stats: PlayerStats(currentStreak: 4, longestStreak: 12, gamesPlayed: 37, bestScore: 142))
}
