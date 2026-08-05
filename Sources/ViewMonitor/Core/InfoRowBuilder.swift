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
    /// nil は選択対象のビューが解放済みであることを意味し、
    /// 共通8行をすべて `None` で返す（前の計測値を出し続けない）。
    static func rows(from inspection: ViewInspection?) -> [InfoRow] {
        guard let inspection else {
            return ["class", "x", "y", "width", "height", "background", "alpha", "cornerRadius"]
                .map { InfoRow(title: $0, value: "None") }
        }
        var rows = [
            InfoRow(title: "class", value: inspection.className),
            InfoRow(title: "x", value: format(inspection.frameInWindow.origin.x)),
            InfoRow(title: "y", value: format(inspection.frameInWindow.origin.y)),
            InfoRow(title: "width", value: format(inspection.size.width)),
            InfoRow(title: "height", value: format(inspection.size.height)),
            InfoRow(title: "background", value: hex(inspection.backgroundColorHex)),
            InfoRow(title: "alpha", value: format(inspection.alpha)),
            InfoRow(title: "cornerRadius", value: format(inspection.cornerRadius))
        ]
        if let font = inspection.font {
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
        if rounded == rounded.rounded() {
            return String(Int(rounded))
        }
        return String(format: "%.1f", rounded)
    }

    private static func hex(_ value: String?) -> String {
        value.map { "#\($0)" } ?? "None"
    }
}
