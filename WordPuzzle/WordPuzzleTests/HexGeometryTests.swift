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
}
