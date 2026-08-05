//
//  InfoRowBuilder.swift
//  ViewMonitor
//

import UIKit

/// InfoView の1行分の表示内容。
struct InfoRow: Equatable {
    let title: String
    let value: String
}

/// ViewInspection から表示行を組み立てる。
/// 条件行（フォント系・距離）と数値・色の整形をすべてここに集約し、
/// UIKit のビュー階層に依存しない純粋関数だけで構成する。
enum InfoRowBuilder {

    /// 表示行を組み立てる。
    /// `inspection` が nil のときは共通8行をすべて `None` で返す。呼び出し側が
    /// 計測対象を取得できなかった場合の防御的な契約で、前の計測値を出し続けない。
    /// `reference` は直前に選択していたビューの計測結果。`inspection` とともに
    /// 非 nil のとき、距離セクション（vs 行＋関係に応じた行）を末尾に加える。
    static func rows(
        from inspection: ViewInspection?,
        comparedTo reference: ViewInspection? = nil
    ) -> [InfoRow] {
        var rows = [
            InfoRow(title: "class", value: inspection?.className ?? "None"),
            InfoRow(title: "x", value: inspection.map { format($0.frameInWindow.origin.x) } ?? "None"),
            InfoRow(title: "y", value: inspection.map { format($0.frameInWindow.origin.y) } ?? "None"),
            InfoRow(title: "width", value: inspection.map { format($0.size.width) } ?? "None"),
            InfoRow(title: "height", value: inspection.map { format($0.size.height) } ?? "None"),
            InfoRow(title: "background", value: inspection.map { hex($0.backgroundColorHex) } ?? "None"),
            InfoRow(title: "alpha", value: inspection.map { format($0.alpha) } ?? "None"),
            InfoRow(title: "cornerRadius", value: inspection.map { format($0.cornerRadius) } ?? "None")
        ]
        if let font = inspection?.font {
            rows.append(InfoRow(title: "font", value: font.familyName))
            rows.append(InfoRow(title: "fontSize", value: format(font.pointSize)))
            rows.append(InfoRow(title: "fontColor", value: hex(font.colorHex)))
        }
        if let inspection, let reference {
            rows.append(contentsOf: distanceRows(from: inspection, to: reference))
        }
        return rows
    }

    /// vs 行と、矩形関係に応じた距離行。
    /// 分離時に投影が重なっている軸（nil）は行を出さない。
    private static func distanceRows(
        from inspection: ViewInspection,
        to reference: ViewInspection
    ) -> [InfoRow] {
        var rows = [InfoRow(title: "vs", value: reference.className)]
        switch RectRelation.between(inspection.frameInWindow, reference.frameInWindow) {
        case .separated(let gapX, let gapY):
            if let gapX {
                rows.append(InfoRow(title: "gapX", value: format(gapX)))
            }
            if let gapY {
                rows.append(InfoRow(title: "gapY", value: format(gapY)))
            }
        case .overlapping(let overlapX, let overlapY):
            rows.append(InfoRow(title: "overlapX", value: format(overlapX)))
            rows.append(InfoRow(title: "overlapY", value: format(overlapY)))
        case .contained(let insets):
            rows.append(InfoRow(title: "top", value: format(insets.top)))
            rows.append(InfoRow(title: "left", value: format(insets.left)))
            rows.append(InfoRow(title: "bottom", value: format(insets.bottom)))
            rows.append(InfoRow(title: "right", value: format(insets.right)))
        }
        return rows
    }

    /// 小数第1位に丸め（四捨五入）、整数になる値は `.0` を落とす。
    /// デザインシートとの照合が目的なので、3x 端末で出る
    /// `16.666666666666668` のような値をそのまま表示しない。
    private static func format(_ value: CGFloat) -> String {
        let rounded = (value * 10).rounded() / 10
        guard rounded.isFinite else {
            return "\(value)"
        }
        if rounded == rounded.rounded() {
            return String(Int(rounded))
        }
        return String(format: "%.1f", rounded)
    }

    private static func hex(_ value: String?) -> String {
        value.map { "#\($0)" } ?? "None"
    }
}
