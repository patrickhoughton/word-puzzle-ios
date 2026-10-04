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

    @Test func testAllCasesCountIsSeven() {
        #expect(SoundEffect.allCases.count == 7)
    }

    // MARK: - Phase 8 effects (D-10, D-16)

    @Test func testNewPhase8RawValues() {
        #expect(SoundEffect.pangramSweep.rawValue == "pangram_sweep")
        #expect(SoundEffect.sweepTick.rawValue == "sweep_tick")
        #expect(SoundEffect.lengthComplete.rawValue == "length_complete")
    }

    @Test func testSweepFanfareIsDistinctFromPangramFound() {
        #expect(SoundEffect.pangramSweep != SoundEffect.pangramFound)
    }

    @Test func testForAcceptedSubmissionWithoutBonusMatchesForSubmission() {
        #expect(SoundEffect.forAcceptedSubmission(isPangram: false, earnedBonus: false) == .wordAccepted)
        #expect(SoundEffect.forAcceptedSubmission(isPangram: true, earnedBonus: false) == .pangramFound)
    }

    @Test func testForAcceptedSubmissionWithBonusIsSilent() {
        #expect(SoundEffect.forAcceptedSubmission(isPangram: true, earnedBonus: true) == nil)
        #expect(SoundEffect.forAcceptedSubmission(isPangram: false, earnedBonus: true) == nil)
    }

    @Test func testDisabledGateCoversSweepFanfare() {
        let manager = SoundManager(preloadPlayers: false)
        manager.play(.pangramSweep, enabled: false)
        #expect(manager.attemptedPlayCount == 0)
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

    // MARK: - forRejection mapping (Phase 6 D-05/D-06)

    @Test func testForRejectionAlreadyFoundIsSilent() {
        #expect(SoundEffect.forRejection(.alreadyFound) == nil)
    }

    @Test func testForRejectionOtherReasonsPlayRejectSound() {
        for reason in [RejectionReason.tooShort, .missingCenterLetter, .notAWord] {
            #expect(SoundEffect.forRejection(reason) == .wordRejected)
        }
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
