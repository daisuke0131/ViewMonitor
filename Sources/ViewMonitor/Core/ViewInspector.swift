//
//  ViewInspector.swift
//  ViewMonitor
//

import UIKit

/// UIView から計測結果を取り出す。
enum ViewInspector {

    /// `view` を `window` の座標系で計測する。
    /// `window` が nil の場合はビュー自身の bounds をそのまま使う。
    @MainActor
    static func inspect(_ view: UIView, in window: UIWindow?) -> ViewInspection {
        ViewInspection(
            frameInWindow: window?.convert(view.bounds, from: view) ?? view.bounds,
            size: view.frame.size,
            backgroundColorHex: view.backgroundColor?.monitorHexString,
            font: fontInfo(of: view)
        )
    }

    @MainActor
    private static func fontInfo(of view: UIView) -> ViewInspection.FontInfo? {
        guard let label = view as? UILabel, let font = label.font else {
            return nil
        }
        return ViewInspection.FontInfo(
            familyName: font.familyName,
            pointSize: font.pointSize,
            colorHex: label.textColor?.monitorHexString
        )
    }
}
