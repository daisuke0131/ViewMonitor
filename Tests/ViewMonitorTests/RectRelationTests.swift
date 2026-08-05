import Testing
import UIKit
@testable import ViewMonitor

@Suite("RectRelation")
struct RectRelationTests {

    @Test("縦に離れている(X投影は重なる)")
    func verticallySeparated() {
        let a = CGRect(x: 0, y: 0, width: 100, height: 20)
        let b = CGRect(x: 0, y: 44, width: 100, height: 20)

        #expect(RectRelation.between(a, b) == .separated(gapX: nil, gapY: 24))
    }

    @Test("横に離れている(Y投影は重なる)")
    func horizontallySeparated() {
        let a = CGRect(x: 0, y: 0, width: 50, height: 20)
        let b = CGRect(x: 58, y: 0, width: 50, height: 20)

        #expect(RectRelation.between(a, b) == .separated(gapX: 8, gapY: nil))
    }

    @Test("斜めに離れている")
    func diagonallySeparated() {
        let a = CGRect(x: 0, y: 0, width: 50, height: 20)
        let b = CGRect(x: 58, y: 44, width: 50, height: 20)

        #expect(RectRelation.between(a, b) == .separated(gapX: 8, gapY: 24))
    }

    @Test("接している辺は gap 0")
    func touchingEdges() {
        let a = CGRect(x: 0, y: 0, width: 100, height: 20)
        let b = CGRect(x: 0, y: 20, width: 100, height: 20)

        #expect(RectRelation.between(a, b) == .separated(gapX: nil, gapY: 0))
    }

    @Test("部分的に重なっている")
    func partiallyOverlapping() {
        let a = CGRect(x: 0, y: 0, width: 100, height: 100)
        let b = CGRect(x: 50, y: 70, width: 100, height: 100)

        #expect(RectRelation.between(a, b) == .overlapping(overlapX: 50, overlapY: 30))
    }

    @Test("内包はインセット4値を返す")
    func containedInsets() {
        let outer = CGRect(x: 0, y: 0, width: 100, height: 100)
        let inner = CGRect(x: 16, y: 12, width: 60, height: 40)

        #expect(RectRelation.between(outer, inner) == .contained(
            insets: UIEdgeInsets(top: 12, left: 16, bottom: 48, right: 24)
        ))
    }

    @Test("内包の判定は引数の順序に依存しない")
    func containmentIsDirectionAgnostic() {
        let outer = CGRect(x: 0, y: 0, width: 100, height: 100)
        let inner = CGRect(x: 16, y: 12, width: 60, height: 40)

        #expect(RectRelation.between(outer, inner) == RectRelation.between(inner, outer))
    }

    @Test("同一矩形はインセット0の内包")
    func identicalRects() {
        let rect = CGRect(x: 10, y: 10, width: 50, height: 50)

        #expect(RectRelation.between(rect, rect) == .contained(insets: .zero))
    }
}
