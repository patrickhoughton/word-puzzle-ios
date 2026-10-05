import SwiftUI

/// Phase 12 D-12: cosmetic jackpot for a spin of more than 5 net revolutions that lands every letter home.
/// No score, no rank, no bonus text (Phase 8 D-04..D-06: bonuses count toward rank, so this deliberately is not one).
struct FullCircleView: View {
    static let title = "Full circle!"
    static let announcement = "Full circle! Every letter spun all the way home."
    let startDate: Date
    let reduceMotion: Bool

    var body: some View {
        HStack(spacing: GameTheme.xs) {
            Image(systemName: "sparkles").foregroundStyle(GameTheme.accent)
            Text(Self.title).foregroundStyle(Color.primary)
        }
        .font(GameTheme.headingFont)
        .lineLimit(1).minimumScaleFactor(0.5)
        .padding(.vertical, GameTheme.sm)
        .padding(.horizontal, GameTheme.md)
        .background(GameTheme.secondarySurface, in: Capsule())
        .shadow(color: .black.opacity(GameTheme.celebrationShadowOpacity), radius: GameTheme.celebrationShadowRadius)
        .background { if !reduceMotion { SparkleBurst(startDate: startDate) } }
        .allowsHitTesting(false)
        .accessibilityHidden(true)   // VoiceOver gets one announcement instead
    }
}

private struct SparkleBurst: View {
    let startDate: Date

    var body: some View {
        let side = 2 * GameTheme.fullCircleBurstRadius + 24
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                draw(in: &context, size: size, elapsed: timeline.date.timeIntervalSince(startDate))
            }
        }
        .frame(width: side, height: side)
        .allowsHitTesting(false)
    }

    private func draw(in context: inout GraphicsContext, size: CGSize, elapsed: Double) {
        let progress = elapsed / GameTheme.fullCircleBurstSeconds
        guard progress >= 0, progress < 1 else { return }
        let radius = GameTheme.fullCircleBurstRadius * CGFloat(progress)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        context.opacity = 1 - progress
        let symbol = context.resolve(
            Text(Image(systemName: "sparkle")).font(GameTheme.labelFont).foregroundStyle(GameTheme.overflowGold))
        let count = GameTheme.fullCircleSparkleCount
        for i in 0..<count {
            let a = Double(i) / Double(count) * 2 * Double.pi
            let point = CGPoint(x: center.x + radius * CGFloat(cos(a)), y: center.y + radius * CGFloat(sin(a)))
            context.draw(symbol, at: point)
        }
    }
}

#Preview("Full circle") { FullCircleView(startDate: .now, reduceMotion: false).padding(120) }
#Preview("Full circle, Reduce Motion") { FullCircleView(startDate: .now, reduceMotion: true).padding(120) }
