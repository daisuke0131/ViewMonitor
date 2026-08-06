//
//  ViewInspection.swift
//  ViewMonitor
//

import UIKit

/// ビュー1つ分の計測結果。
/// 表示側はこの値を受け取って描画するだけにし、計測ロジックを持たせない。
struct ViewInspection: Equatable {

    /// モジュール名を除いたクラス名。KVO 合成クラスは本来のクラスに正規化済み。
    let className: String

    /// ウィンドウ座標系での位置とサイズ。
    let frameInWindow: CGRect

    /// ビュー自身のサイズ。
    let size: CGSize

    /// 背景色（`RRGGBB`）。取得できない場合は nil。
    let backgroundColorHex: String?

    /// 不透明度。SwiftUI のアクセシビリティ要素では取得できないため nil。
    let alpha: CGFloat?

    /// 角丸の半径。SwiftUI のアクセシビリティ要素では取得できないため nil。
    let cornerRadius: CGFloat?

    /// テキスト内容。SwiftUI 要素の accessibilityLabel。UIKit ビューでは nil。
    let text: String?

    /// フォント情報。テキストを持つビュー（UILabel / UIButton）以外は nil。
    let font: FontInfo?

    struct FontInfo: Equatable {
        let familyName: String
        let pointSize: CGFloat
        /// 文字色（`RRGGBB`）。取得できない場合は nil。
        let colorHex: String?
    }
}
