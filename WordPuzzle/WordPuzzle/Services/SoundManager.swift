import AVFoundation
import Foundation

/// UX-02 / D-01: the four events that produce a sound effect.
/// Raw values are the bundled filenames (see Sounds/LICENSE.txt).
enum SoundEffect: String, CaseIterable {
    case wordAccepted = "word_accepted"
    case wordRejected = "word_rejected"
    case pangramFound = "pangram_found"
    case roundEnd     = "round_end"

    static let fileExtension = "wav"

    /// D-01: a pangram gets a distinct, bigger sound than a plain accept.
    /// Rejection always wins -- a rejected word is never counted as a pangram.
    static func forSubmission(accepted: Bool, isPangram: Bool) -> SoundEffect {
        guard accepted else { return .wordRejected }
        return isPangram ? .pangramFound : .wordAccepted
    }

    /// Phase 6 D-05 / D-06: a duplicate ("already found") is a friendly reminder, not a
    /// mistake, so it plays NO sound. Every other rejection reason keeps the reject sound.
    static func forRejection(_ reason: RejectionReason) -> SoundEffect? {
        switch reason {
        case .alreadyFound:                              return nil
        case .tooShort, .missingCenterLetter, .notAWord: return .wordRejected
        }
    }

    /// D-01 groups "round end" and "paywall shown" into ONE sound. On a cold
    /// launch a free user already at the daily limit goes .loading -> .paywalled,
    /// so this fires at launch with no preceding round. That is intended, not a bug.
    static func forRoundPhase(_ phase: GameViewModel.RoundPhase) -> SoundEffect? {
        switch phase {
        case .roundOver, .paywalled: return .roundEnd
        case .loading, .playing:     return nil
        }
    }
}

/// UX-02: preloaded one-shot SFX playback, gated by the user's sound preference.
///
/// Deliberately NOT `@Observable` and NOT a store: the preference is a single
/// Bool that lives in `@AppStorage` (project convention for simple flags, same as
/// dailyCount / puzzleSeed). The caller passes the flag in -- this type owns no state
/// the UI observes. See RESEARCH "Anti-Patterns to Avoid".
@MainActor
final class SoundManager {
    static let shared = SoundManager()

    /// RESEARCH Pitfall 3: `.ambient` mixes with other audio AND respects the
    /// hardware silent switch, which is what players expect from incidental game
    /// SFX. Never use the category that deliberately overrides the silent switch.
    static let sessionCategory: AVAudioSession.Category = .ambient

    /// The single `@AppStorage` key backing the Settings toggle. Declared here so
    /// the literal string lives in exactly one place (plan 05-05 reads it).
    static let soundEffectsEnabledKey = "soundEffectsEnabled"

    /// Test seam: `play(_:enabled:)` records the attempt before touching
    /// AVAudioPlayer, so the enabled gate is unit-testable without asserting on
    /// real audio output. Bounded -- stores only the last effect plus a counter.
    private(set) var lastAttemptedEffect: SoundEffect?
    private(set) var attemptedPlayCount: Int = 0

    private var players: [SoundEffect: AVAudioPlayer] = [:]

    /// - Parameter preloadPlayers: pass `false` in tests that only exercise the
    ///   gate/mapping logic, so no AVAudioPlayer or audio session is touched.
    init(preloadPlayers: Bool = true) {
        guard preloadPlayers else { return }
        try? AVAudioSession.sharedInstance().setCategory(Self.sessionCategory)
        for effect in SoundEffect.allCases {
            guard let url = Bundle.main.url(forResource: effect.rawValue,
                                            withExtension: SoundEffect.fileExtension),
                  let player = try? AVAudioPlayer(contentsOf: url) else { continue }
            player.prepareToPlay()
            players[effect] = player
        }
    }

    /// No-op when `enabled` is false. All four call sites in GameView pass the
    /// `@AppStorage(SoundManager.soundEffectsEnabledKey)` value straight through.
    func play(_ effect: SoundEffect, enabled: Bool) {
        guard enabled else { return }
        lastAttemptedEffect = effect
        attemptedPlayCount += 1
        guard let player = players[effect] else { return }
        player.stop()
        player.currentTime = 0
        player.play()
    }
}
