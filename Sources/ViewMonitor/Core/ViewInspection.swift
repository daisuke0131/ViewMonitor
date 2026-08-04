//
//  ViewInspection.swift
//  ViewMonitor
//

import UIKit

/// ビュー1つ分の計測結果。
/// 表示側はこの値を受け取って描画するだけにし、計測ロジックを持たせない。
struct ViewInspection: Equatable {

    /// ウィンドウ座標系での位置とサイズ。
    let frameInWindow: CGRect

    /// ビュー自身のサイズ。
    let size: CGSize

    /// 背景色（`RRGGBB`）。取得できない場合は nil。
    let backgroundColorHex: String?

    /// フォント情報。UILabel 以外は nil。
    let font: FontInfo?

    struct FontInfo: Equatable {
        let familyName: String
        let pointSize: CGFloat
        /// 文字色（`RRGGBB`）。取得できない場合は nil。
        let colorHex: String?
    }
}
