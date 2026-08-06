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
            className: ViewHierarchyScanner.className(of: view),
            frameInWindow: window?.convert(view.bounds, from: view) ?? view.bounds,
            size: view.frame.size,
            backgroundColorHex: view.backgroundColor?.monitorHexString,
            alpha: view.alpha,
            cornerRadius: view.layer.cornerRadius,
            text: nil,
            font: fontInfo(of: view)
        )
    }

    @MainActor
    private static func fontInfo(of view: UIView) -> ViewInspection.FontInfo? {
        guard let label = textLabel(of: view), let font = label.font else {
            return nil
        }
        return ViewInspection.FontInfo(
            familyName: font.familyName,
            pointSize: font.pointSize,
            colorHex: label.textColor?.monitorHexString
        )
    }

    /// フォント情報の供給元となるラベル。
    /// UIButton はタイトル未設定などで `titleLabel` が nil のことがあり、その場合はフォント行を出さない。
    @MainActor
    private static func textLabel(of view: UIView) -> UILabel? {
        switch view {
        case let label as UILabel:
            return label
        case let button as UIButton:
            return button.titleLabel
        default:
            return nil
        }
    }
}
