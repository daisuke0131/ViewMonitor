//
//  MonitorShieldView.swift
//  ViewMonitor
//

import UIKit

/// 計測中にアプリ本体へのタッチを遮る透明ビュー。
///
/// 計測ボタンに覆われていない領域へのタップ・スクロール・エッジスワイプが
/// アプリ側に届くと、ボタンの誤発火だけでなく、画面遷移で計測状態ごと
/// 破棄されてしまう(遷移検知の reload が実行ボタンを OFF の新品に差し替える)。
///
/// rootView 直下・計測 UI より背面に挟み、アプリ本体宛てのタッチを吸収する。
/// InfoView・SwiftUI 要素の計測ボタン・実行ボタンはこの盾より前面に居るため
/// 影響を受けない。UIKit 対象の計測ボタンだけは対象ビューの subview として
/// アプリ階層の内側(盾より背面)に追加されるので、ヒットテストで判別して通す。
final class MonitorShieldView: UIView {

    /// 背面の引き直し中かどうか。
    /// isHidden を一時的に立てて自分を除外する方法は使えない。UIKit 内部の
    /// ヒットテスト経路には hidden を確認せず hitTest を呼び直すものがあり、
    /// 無限再帰でスタックオーバーフローする(実測)。ヒットテスト中に
    /// ビューの状態を変えること自体も CA の再計算を誘発するため避ける。
    private var isRequeryingBelow = false

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // 引き直しから再入されたときは自分を透明扱いにし、
        // 親の走査を盾より背面のビューへ進ませる。
        if isRequeryingBelow {
            return nil
        }
        guard let superview else {
            return super.hitTest(point, with: event)
        }
        // 背面を引き直し、UIKit 対象ビュー内の計測ボタン(盾より背面に居る)
        // 宛てのタッチだけを通す。
        isRequeryingBelow = true
        defer {
            isRequeryingBelow = false
        }
        let below = superview.hitTest(convert(point, to: superview), with: event)
        guard let below else {
            return self
        }
        let isMonitorButton = sequence(first: below, next: { $0.superview })
            .contains { $0 is MonitorButton }
        return isMonitorButton ? nil : self
    }
}
