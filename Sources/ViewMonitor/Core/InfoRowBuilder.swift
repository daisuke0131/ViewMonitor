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
/// 条件行（フォント系）と数値・色の整形をすべてここに集約し、
/// UIKit のビュー階層に依存しない純粋関数だけで構成する。
enum InfoRowBuilder {

    /// 表示行を組み立てる。
    /// nil のときは共通8行をすべて `None` で返す。呼び出し側が計測対象を
    /// 取得できなかった場合の防御的な契約で、前の計測値を出し続けない。
    static func rows(from inspection: ViewInspection?) -> [InfoRow] {
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
