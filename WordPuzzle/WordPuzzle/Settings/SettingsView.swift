import SwiftUI

/// UX-02 / D-03: the settings screen is deliberately minimal — ONE control,
/// the sound-effects toggle. A haptics toggle and the lifetime-stats screen
/// (backlog Phase 999.1) were both explicitly considered and deferred.
///
/// Presentation-only: takes a Binding and a closure, holds no stored preference and
/// no environment/store reads. The preference itself is owned by GameView, matching
/// the Phase 3/4 rule that every non-GameView view is value-in/closure-out.
struct SettingsView: View {
    /// Frozen copy (05-UI-SPEC.md Copywriting Contract) — pinned as constants so
    /// SettingsViewTests can assert on it, same pattern as PaywallView's strings.
    static let title = "Settings"
    static let soundToggleLabel = "Sound Effects"
    static let doneButtonLabel = "Done"
    static let settingsEntryAccessibilityLabel = "Settings"

    @Binding var soundEffectsEnabled: Bool
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: GameTheme.md) {
                Toggle(Self.soundToggleLabel, isOn: $soundEffectsEnabled)
                    .font(GameTheme.bodyFont)
                    .padding(GameTheme.md)

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
