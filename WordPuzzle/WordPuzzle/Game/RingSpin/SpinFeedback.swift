import UIKit
import QuartzCore

/// Phase 12 D-10/D-11/D-12: imperative feedback because ticks arrive up to ~20/s (`.sensoryFeedback` only
/// fires after a rendered state change and lags). Haptics are NOT gated by soundEffectsEnabled (that flag is
/// sound-only; the system Haptics setting applies automatically). Sounds use the existing `.ambient` session,
/// so the silent switch silences them. Shuffle stays silent (Phase 10 D-09); spinning is deliberately audible.
@MainActor
final class SpinFeedback {
    private let sound: SoundManager
    private let clock: () -> TimeInterval
    private var throttle: TickThrottle
    private var lastPrepare: TimeInterval = -.infinity

    private let tickGenerator = UIImpactFeedbackGenerator(style: .light)
    private let clunkGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let jackpotGenerator = UINotificationFeedbackGenerator()

    init(sound: SoundManager = .shared,
         clock: @escaping () -> TimeInterval = { CACurrentMediaTime() },
         throttle: TickThrottle = TickThrottle()) {
        self.sound = sound
        self.clock = clock
        self.throttle = throttle
    }

    func prepare() {
        throttle.reset()
        tickGenerator.prepare()
        clunkGenerator.prepare()
        lastPrepare = clock()
    }

    func ticks(count: Int, speed: Double, soundEnabled: Bool) {
        let now = clock()
        if now - lastPrepare > 1 { tickGenerator.prepare(); clunkGenerator.prepare(); lastPrepare = now }
        let rate = speed / SlotMath.slotAngle
        let decision = throttle.register(crossings: count, at: now, rate: rate)
        let f = min(1, speed / 12)
        if decision.haptic { tickGenerator.impactOccurred(intensity: 0.4 + 0.4 * f) }
        if decision.sound { sound.playSpinTick(enabled: soundEnabled, volume: Float(0.3 + 0.2 * f)) }
    }

    func clunk(soundEnabled: Bool) {
        clunkGenerator.impactOccurred(intensity: 0.9)
        sound.play(.spinClunk, enabled: soundEnabled)
    }

    func jackpot(soundEnabled: Bool) {
        jackpotGenerator.notificationOccurred(.success)
        sound.play(.fullCircle, enabled: soundEnabled)
    }
}
