import Testing
import Foundation
import AVFoundation
@testable import WordPuzzle

/// UX-02 / D-01: SoundManager's enabled gate, event mapping, session category
/// and resource-bundling behavior.
@MainActor
@Suite struct SoundManagerTests {

    // MARK: - Enabled gate (test seam: attemptedPlayCount / lastAttemptedEffect)

    @Test func testPlayDisabledIsANoOp() {
        let manager = SoundManager(preloadPlayers: false)
        manager.play(.wordAccepted, enabled: false)
        #expect(manager.attemptedPlayCount == 0)
        #expect(manager.lastAttemptedEffect == nil)
    }

    @Test func testPlayEnabledRecordsAttempt() {
        let manager = SoundManager(preloadPlayers: false)
        manager.play(.wordAccepted, enabled: true)
        #expect(manager.attemptedPlayCount == 1)
        #expect(manager.lastAttemptedEffect == .wordAccepted)
    }

    @Test func testTwoEnabledCallsIncrementCount() {
        let manager = SoundManager(preloadPlayers: false)
        manager.play(.wordAccepted, enabled: true)
        manager.play(.wordRejected, enabled: true)
        #expect(manager.attemptedPlayCount == 2)
        #expect(manager.lastAttemptedEffect == .wordRejected)
    }

    // MARK: - SoundEffect case count

    @Test func testAllCasesCountIsFour() {
        #expect(SoundEffect.allCases.count == 4)
    }

    // MARK: - forSubmission mapping (D-01)

    @Test func testForSubmissionAcceptedNonPangram() {
        #expect(SoundEffect.forSubmission(accepted: true, isPangram: false) == .wordAccepted)
    }

    @Test func testForSubmissionAcceptedPangram() {
        #expect(SoundEffect.forSubmission(accepted: true, isPangram: true) == .pangramFound)
    }

    @Test func testForSubmissionRejectedNonPangram() {
        #expect(SoundEffect.forSubmission(accepted: false, isPangram: false) == .wordRejected)
    }

    @Test func testForSubmissionRejectedIgnoresPangramFlag() {
        // Rejection wins -- a rejected word is never counted as a pangram.
        #expect(SoundEffect.forSubmission(accepted: false, isPangram: true) == .wordRejected)
    }

    // MARK: - forRoundPhase mapping (D-01)

    @Test func testForRoundPhaseRoundOverAndPaywalledMapToRoundEnd() {
        #expect(SoundEffect.forRoundPhase(.roundOver) == .roundEnd)
        #expect(SoundEffect.forRoundPhase(.paywalled) == .roundEnd)
    }

    @Test func testForRoundPhasePlayingAndLoadingMapToNil() {
        #expect(SoundEffect.forRoundPhase(.playing) == nil)
        #expect(SoundEffect.forRoundPhase(.loading) == nil)
    }

    // MARK: - Static configuration (RESEARCH Pitfall 3)

    @Test func testSessionCategoryIsAmbient() {
        #expect(SoundManager.sessionCategory == .ambient)
    }

    @Test func testSoundEffectsEnabledKeyLiteral() {
        #expect(SoundManager.soundEffectsEnabledKey == "soundEffectsEnabled")
    }

    // MARK: - Resource bundling (proves Task 1's synchronized-group assumption)

    @Test func testAllEffectsAreBundled() {
        for effect in SoundEffect.allCases {
            let url = Bundle.main.url(forResource: effect.rawValue,
                                       withExtension: SoundEffect.fileExtension)
            #expect(url != nil, "\(effect.rawValue).\(SoundEffect.fileExtension) not found in app bundle")
        }
    }
}
