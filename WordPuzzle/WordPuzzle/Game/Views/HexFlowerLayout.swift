import SwiftUI

/// Pure geometry for the fixed 7-tile honeycomb flower (D-01).
/// Extracted from LetterGridView so the trigonometry is unit-testable without
/// rendering a view (RESEARCH: a fixed 7-tile cluster does not warrant the
/// SwiftUI `Layout` protocol — a ZStack + .offset is simpler and sufficient).
enum HexFlowerLayout {

    /// Offsets from the grid center for the 6 outer tiles.
    /// Index 0 is straight up (12 o'clock), then clockwise every 60°.
    /// Note: SwiftUI's y-axis grows downward, so "up" is a negative height.
    static func outerOffsets(radius: CGFloat = GameTheme.outerRingRadius) -> [CGSize] {
        (0..<6).map { i in
            let angle = Angle(degrees: Double(i) * 60 - 90)
            return CGSize(
                width: radius * cos(angle.radians),
                height: radius * sin(angle.radians)
            )
        }
    }

    /// Total square side needed to fit the whole flower without clipping.
    static func flowerDiameter(
        hexSize: CGFloat = GameTheme.hexSize,
        radius: CGFloat = GameTheme.outerRingRadius
    ) -> CGFloat {
        radius * 2 + hexSize
    }

    /// True if `point` lands on the tile whose center is `tileCenter`.
    /// Uses a circular test inscribed in the hexagon: simpler than a polygon
    /// point-in-shape test and avoids the corner-overlap problem where two
    /// adjacent tiles' bounding rects intersect (RESEARCH Pitfall 4).
    static func hitTest(point: CGPoint, tileCenter: CGPoint, hexSize: CGFloat = GameTheme.hexSize) -> Bool {
        hypot(point.x - tileCenter.x, point.y - tileCenter.y) <= hexSize / 2
    }
}
