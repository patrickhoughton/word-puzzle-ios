import SwiftUI

/// Pure geometry for the fixed 7-tile honeycomb flower (D-01).
/// Extracted from LetterGridView so the trigonometry is unit-testable without
/// rendering a view (RESEARCH: a fixed 7-tile cluster does not warrant the
/// SwiftUI `Layout` protocol — a ZStack + .offset is simpler and sufficient).
enum HexFlowerLayout {

    /// Offsets from the grid center for the 6 outer tiles.
    /// Index 0 is straight up (12 o'clock), then clockwise every 60°.
    /// Note: SwiftUI's y-axis grows downward, so "up" is a negative height.
    /// Phase 12 D-07: only POSITIONS rotate; tiles are never given a rotation
    /// modifier, so glyphs stay upright (Ferris wheel). `rotation` is radians,
    /// positive = clockwise; 0 keeps today's positions.
    static func outerOffsets(radius: CGFloat = GameTheme.outerRingRadius, rotation: Double = 0) -> [CGSize] {
        (0..<6).map { i in
            let a = Angle(degrees: Double(i) * 60 - 90).radians + rotation
            return CGSize(
                width: radius * cos(a),
                height: radius * sin(a)
            )
        }
    }

    /// Phase 12 D-09: committing a spin of k slots. Matches
    /// outerOffsets(rotation: k * pi/3): the letter at index i was drawn at
    /// slot i + k, and after the commit it lives at index (i + k) mod 6, so the
    /// on-screen position is identical (the commit is a visual no-op when tiles
    /// are keyed by letter). Negative k = counter-clockwise.
    static func rotated<T>(_ items: [T], bySlots k: Int) -> [T] {
        let n = items.count
        guard n > 0 else { return items }
        let s = ((k % n) + n) % n
        guard s != 0 else { return items }
        var out = items
        for i in 0..<n { out[(i + s) % n] = items[i] }
        return out
    }

    /// Phase 12 D-01: extra grab room outside the flower square. Kept below
    /// GameTheme.xl (32), the Spacer minimum between the grid and the control
    /// row in GameView, and well below xxl (48) above it, so the zone never
    /// overlaps the word display or the buttons (research Pitfall 5).
    static let spinZoneMargin: CGFloat = 28

    /// Side of the padded square the grid's gesture lives in.
    static func spinZoneSide() -> CGFloat { flowerDiameter() + 2 * spinZoneMargin }

    /// Flower center in the padded gesture view's local coordinates.
    static var spinZoneCenter: CGPoint { CGPoint(x: spinZoneSide() / 2, y: spinZoneSide() / 2) }

    /// -1 = center tile, 0...5 = outer tile by current index, nil = off every
    /// tile (spin zone). Phase 12: pure replacement for the GeometryReader
    /// frame preferences (which would fire every frame while the ring moves).
    /// Reuses the inscribed-circle hitTest (Phase 3 Pitfall 4).
    static func tileIndex(at point: CGPoint, center: CGPoint, rotation: Double = 0,
                          hexSize: CGFloat = GameTheme.hexSize,
                          radius: CGFloat = GameTheme.outerRingRadius) -> Int? {
        if hitTest(point: point, tileCenter: center, hexSize: hexSize) { return -1 }
        let offsets = outerOffsets(radius: radius, rotation: rotation)
        for (i, o) in offsets.enumerated() {
            let c = CGPoint(x: center.x + o.width, y: center.y + o.height)
            if hitTest(point: point, tileCenter: c, hexSize: hexSize) { return i }
        }
        return nil
    }

    /// atan2(dy, dx): radians, clockwise-positive on screen.
    static func touchAngle(of point: CGPoint, center: CGPoint) -> Double {
        atan2(Double(point.y - center.y), Double(point.x - center.x))
    }

    /// True within hexSize / 2 of the center, where atan2 is unstable.
    static func isInCenterDeadZone(_ point: CGPoint, center: CGPoint, hexSize: CGFloat = GameTheme.hexSize) -> Bool {
        hypot(point.x - center.x, point.y - center.y) < hexSize / 2
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
