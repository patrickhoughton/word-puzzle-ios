import SwiftUI

/// Flat-top regular hexagon. Six vertices at 60° increments starting at -30°,
/// which puts flat edges on the top and bottom (RESEARCH Pattern 1).
/// Used for BOTH `.clipShape` (visual) and `.contentShape` (hit-testing) —
/// clipShape alone does NOT restrict hit-testing (RESEARCH Pitfall 4).
struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        for i in 0..<6 {
            let angle = Angle(degrees: Double(i) * 60 - 30)
            let point = CGPoint(
                x: center.x + radius * cos(angle.radians),
                y: center.y + radius * sin(angle.radians)
            )
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}
