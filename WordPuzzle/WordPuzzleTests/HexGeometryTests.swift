import Testing
import SwiftUI
import CoreGraphics
@testable import WordPuzzle

@Suite struct HexGeometryTests {

    @Test func testHexagonPathIsClosedAndFitsItsRect() {
        let rect = CGRect(x: 0, y: 0, width: 70, height: 70)
        let path = HexagonShape().path(in: rect)
        #expect(!path.isEmpty)
        let bounds = path.boundingRect
        #expect(bounds.width <= 70.001)
        #expect(bounds.height <= 70.001)
        #expect(abs(bounds.midX - 35) < 0.001)
        #expect(abs(bounds.midY - 35) < 0.001)
    }

    @Test func testOuterOffsetsAreSixDistinctPointsOnTheRing() {
        let offsets = HexFlowerLayout.outerOffsets(radius: 112)
        #expect(offsets.count == 6)
        for offset in offsets {
            #expect(abs(hypot(offset.width, offset.height) - 112) < 0.001)
        }
        // Pairwise distinct (compare rounded values to avoid float noise)
        let rounded = Set(offsets.map { "\(Int($0.width.rounded())),\(Int($0.height.rounded()))" })
        #expect(rounded.count == 6)
    }

    @Test func testFirstOuterOffsetPointsStraightUp() {
        let offsets = HexFlowerLayout.outerOffsets(radius: 112)
        #expect(abs(offsets[0].width) < 0.001)
        #expect(abs(offsets[0].height + 112) < 0.001)
    }

    @Test func testHitTestAcceptsCenterAndRejectsOutside() {
        let center = CGPoint(x: 100, y: 100)
        #expect(HexFlowerLayout.hitTest(point: center, tileCenter: center, hexSize: 70))
        #expect(HexFlowerLayout.hitTest(point: CGPoint(x: 130, y: 100), tileCenter: center, hexSize: 70))
        #expect(!HexFlowerLayout.hitTest(point: CGPoint(x: 140, y: 100), tileCenter: center, hexSize: 70))
    }

    @Test func testFlowerDiameterCoversTheWholeRing() {
        #expect(HexFlowerLayout.flowerDiameter(hexSize: 70, radius: 112) == 294)
    }

    // MARK: Phase 12 rotation

    private func close(_ a: CGSize, _ b: CGSize) -> Bool {
        abs(a.width - b.width) < 1e-9 && abs(a.height - b.height) < 1e-9
    }

    @Test func rotationZeroMatchesDefault() {
        let a = HexFlowerLayout.outerOffsets(radius: 112, rotation: 0)
        let b = HexFlowerLayout.outerOffsets(radius: 112)
        for i in 0..<6 { #expect(close(a[i], b[i])) }
    }

    @Test func rotationByOneSlotIsClockwise() {
        let r = HexFlowerLayout.outerOffsets(radius: 112, rotation: .pi / 3)
        let base = HexFlowerLayout.outerOffsets(radius: 112)
        #expect(close(r[0], base[1]))
    }

    @Test func rotatedOffsetsStayOnRing() {
        for o in HexFlowerLayout.outerOffsets(radius: 112, rotation: 0.37) {
            #expect(abs(hypot(o.width, o.height) - 112) < 1e-9)
        }
    }

    @Test func cyclicRotationBehaviour() {
        let l = ["a", "b", "c", "d", "e", "f"]
        #expect(HexFlowerLayout.rotated(l, bySlots: 1) == ["f", "a", "b", "c", "d", "e"])
        #expect(HexFlowerLayout.rotated(l, bySlots: -1) == ["b", "c", "d", "e", "f", "a"])
        #expect(HexFlowerLayout.rotated(l, bySlots: 6) == l)
        #expect(HexFlowerLayout.rotated(l, bySlots: 0) == l)
        #expect(HexFlowerLayout.rotated(l, bySlots: 7) == HexFlowerLayout.rotated(l, bySlots: 1))
        #expect(HexFlowerLayout.rotated(l, bySlots: -13) == HexFlowerLayout.rotated(l, bySlots: -1))
        #expect(HexFlowerLayout.rotated([String](), bySlots: 3) == [])
    }

    @Test func commitIsPositionContinuous() {
        let letters = ["a", "b", "c", "d", "e", "f"]
        let base = HexFlowerLayout.outerOffsets()
        for k in -7...7 {
            let spun = HexFlowerLayout.outerOffsets(rotation: Double(k) * .pi / 3)
            let committed = HexFlowerLayout.rotated(letters, bySlots: k)
            for i in 0..<6 {
                let j = committed.firstIndex(of: letters[i])!
                #expect(close(spun[i], base[j]))
            }
        }
    }

    // MARK: Phase 12 classification

    @Test func spinZoneGeometry() {
        #expect(HexFlowerLayout.spinZoneMargin == 28)
        #expect(HexFlowerLayout.spinZoneMargin < GameTheme.xl)
        #expect(HexFlowerLayout.spinZoneSide() == HexFlowerLayout.flowerDiameter() + 56)
        #expect(HexFlowerLayout.spinZoneSide() == 350)
        #expect(HexFlowerLayout.spinZoneSide() <= 375)
        #expect(HexFlowerLayout.spinZoneCenter == CGPoint(x: 175, y: 175))
    }

    @Test func tileIndexClassification() {
        let c = HexFlowerLayout.spinZoneCenter
        #expect(HexFlowerLayout.tileIndex(at: c, center: c) == -1)
        let offs = HexFlowerLayout.outerOffsets()
        for i in 0..<6 {
            let p = CGPoint(x: c.x + offs[i].width, y: c.y + offs[i].height)
            #expect(HexFlowerLayout.tileIndex(at: p, center: c) == i)
        }
        let ro = HexFlowerLayout.outerOffsets(rotation: 0.4)[2]
        #expect(HexFlowerLayout.tileIndex(at: CGPoint(x: c.x + ro.width, y: c.y + ro.height),
                                          center: c, rotation: 0.4) == 2)
        #expect(HexFlowerLayout.tileIndex(at: CGPoint(x: 175, y: 175 - 56), center: c) == nil)
        #expect(HexFlowerLayout.tileIndex(at: CGPoint(x: 0, y: 0), center: c) == nil)
        #expect(HexFlowerLayout.tileIndex(at: CGPoint(x: 175, y: 175 - 160), center: c) == nil)
    }

    @Test func touchAngleAndDeadZone() {
        let c = HexFlowerLayout.spinZoneCenter
        #expect(HexFlowerLayout.touchAngle(of: CGPoint(x: 275, y: 175), center: c) == 0)
        #expect(abs(HexFlowerLayout.touchAngle(of: CGPoint(x: 175, y: 275), center: c) - .pi / 2) < 1e-9)
        #expect(abs(HexFlowerLayout.touchAngle(of: CGPoint(x: 175, y: 75), center: c) + .pi / 2) < 1e-9)
        #expect(HexFlowerLayout.isInCenterDeadZone(CGPoint(x: 209, y: 175), center: c))
        #expect(!HexFlowerLayout.isInCenterDeadZone(CGPoint(x: 211, y: 175), center: c))
    }
}
