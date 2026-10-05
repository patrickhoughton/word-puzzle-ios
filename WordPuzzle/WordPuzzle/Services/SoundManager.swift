import AVFoundation
import Foundation

/// UX-02 / D-01: the events that produce a sound effect (four from UX-02, three added in Phase 8, three in Phase 12).
/// Raw values are the bundled filenames (see Sounds/LICENSE.txt).
enum SoundEffect: String, CaseIterable {
    case wordAccepted = "word_accepted"
    case wordRejected = "word_rejected"
    case pangramFound = "pangram_found"
    case roundEnd     = "round_end"
    /// Phase 8 D-10: the pangram-sweep fanfare, played on the tally's final frame. Distinct from pangramFound.
    case pangramSweep   = "pangram_sweep"
    /// Phase 8 D-10: one tick per tally step (throttled to <= 12, CompletionCelebration.shouldTick).
    case sweepTick      = "sweep_tick"
    /// Phase 8 D-16: lighter chime when a length group is completed.
    case lengthComplete = "length_complete"
    /// Phase 12 D-10/D-11: one soft click per slot boundary (throttled by TickThrottle).
    case spinTick   = "spin_tick"
    /// Phase 12 D-06/D-10: firmer landing clunk.
    case spinClunk  = "spin_clunk"
    /// Phase 12 D-12: cosmetic jackpot.
    case fullCircle = "full_circle"

    static let fileExtension = "wav"

    /// Phase 8 UI-SPEC 5: when the accepted word earned a completion bonus, the celebration's own
    /// sound (length chime, or tally ticks + sweep fanfare) REPLACES the per-word accept/pangram sound,
    /// so nothing double-plays. Returns nil in that case.
    static func forAcceptedSubmission(isPangram: Bool, earnedBonus: Bool) -> SoundEffect? {
        earnedBonus ? nil : forSubmission(accepted: true, isPangram: isPangram)
    }

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

    /// Phase 12 D-11: round-robin pool so rapid ticks never cut each other off.
    static let spinTickPoolSize = 4
    private var tickPool: [AVAudioPlayer] = []
    private var tickPoolIndex = 0

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
        if let url = Bundle.main.url(forResource: SoundEffect.spinTick.rawValue,
                                     withExtension: SoundEffect.fileExtension) {
            for _ in 0..<Self.spinTickPoolSize {
                guard let player = try? AVAudioPlayer(contentsOf: url) else { continue }
                player.prepareToPlay()
                tickPool.append(player)
            }
        }
    }

    /// No-op when `enabled` is false. All call sites in GameView pass the
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

    /// Phase 12 D-11: ticks can arrive ~20/s. A single player would be stop()/restarted every tick
    /// (clipped, buzzy), so ticks round-robin across a small pool. Same enabled gate + test seam as play(_:enabled:).
    func playSpinTick(enabled: Bool, volume: Float) {
        guard enabled else { return }
        lastAttemptedEffect = .spinTick
        attemptedPlayCount += 1
        guard !tickPool.isEmpty else { return }
        let player = tickPool[tickPoolIndex]
        tickPoolIndex = (tickPoolIndex + 1) % tickPool.count
        player.volume = max(0, min(1, volume))
        player.currentTime = 0
        player.play()
    }
}
