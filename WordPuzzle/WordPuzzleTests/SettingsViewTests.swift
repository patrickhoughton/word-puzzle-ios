import Testing
import Foundation
import SwiftUI
@testable import WordPuzzle

/// UX-02 / D-03: the Settings screen's copy is frozen (05-UI-SPEC.md Copywriting
/// Contract), so it is pinned by tests rather than eyeballed on device, mirroring
/// PaywallViewTests.swift's structure.
@MainActor
@Suite struct SettingsViewTests {

    @Test func testTitleIsFrozen() {
        #expect(SettingsView.title == "Settings")
    }

    @Test func testSoundToggleLabelIsFrozen() {
        #expect(SettingsView.soundToggleLabel == "Sound Effects")
    }

    @Test func testDoneButtonLabelIsFrozen() {
        #expect(SettingsView.doneButtonLabel == "Done")
    }

    @Test func testSettingsEntryAccessibilityLabelIsFrozen() {
        #expect(SettingsView.settingsEntryAccessibilityLabel == "Settings")
    }

    @Test func testStatsRowLabelIsFrozen() {
        #expect(SettingsView.statsRowLabel == "Stats")
    }

    @Test func testStatsDefaultsToEmptySnapshot() {
        #expect(SettingsView(soundEffectsEnabled: .constant(true), onDone: {}).stats == .empty)
    }

    @Test func testStatsSnapshotIsPassedThrough() {
        #expect(SettingsView(soundEffectsEnabled: .constant(true), onDone: {}, stats: PlayerStats(gamesPlayed: 3)).stats.gamesPlayed == 3)
    }
}
