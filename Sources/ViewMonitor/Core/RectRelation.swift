//
//  RectRelation.swift
//  ViewMonitor
//

import UIKit

/// 2つの矩形の位置関係。ビュー階層に依存しない純粋な判定。
enum RectRelation: Equatable {

    /// 少なくとも一方の軸で離れている。投影が重なっている軸は nil。
    /// 0 は「ぴったり接している」を意味する有効値。
    case separated(gapX: CGFloat?, gapY: CGFloat?)

    /// 両軸で投影が重なっているが、内包ではない。値は重なり幅（正）。
    case overlapping(overlapX: CGFloat, overlapY: CGFloat)

    /// 一方が他方を内包する。インセットは常に「内側の矩形の、外側の
    /// 矩形の各辺からの距離」で、どちらを先に渡しても同じ値になる。
    case contained(insets: UIEdgeInsets)

    /// `a` と `b` の位置関係を判定する。
    /// サイズ 0 の矩形は `contains` が偽になり gap 計算に落ちる（許容）。
    static func between(_ a: CGRect, _ b: CGRect) -> RectRelation {
        if a.contains(b) || b.contains(a) {
            let outer = a.contains(b) ? a : b
            let inner = a.contains(b) ? b : a
            return .contained(insets: UIEdgeInsets(
                top: inner.minY - outer.minY,
                left: inner.minX - outer.minX,
                bottom: outer.maxY - inner.maxY,
                right: outer.maxX - inner.maxX
            ))
        }
        let gapX = max(a.minX, b.minX) - min(a.maxX, b.maxX)
        let gapY = max(a.minY, b.minY) - min(a.maxY, b.maxY)
        if gapX < 0 && gapY < 0 {
            return .overlapping(overlapX: -gapX, overlapY: -gapY)
        }
        return .separated(
            gapX: gapX >= 0 ? gapX : nil,
            gapY: gapY >= 0 ? gapY : nil
        )
    }
}
