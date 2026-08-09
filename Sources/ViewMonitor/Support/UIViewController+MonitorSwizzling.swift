//
//  UIViewController+MonitorSwizzling.swift
//  ViewMonitor
//

import UIKit

@MainActor
extension UIViewController {

    private static var swizzlingInstallCount = 0
    private static var installedImplementation: IMP?

    /// swizzling が適用された回数。奇数回でなければ検知が働かないため、
    /// 常に 1 であることをテストで保証する。
    static var monitorSwizzlingInstallCount: Int { swizzlingInstallCount }

    /// `viewDidAppear` が現在 ViewMonitor のラッパーに向いているか。
    /// 誰か（他ライブラリの追加的な swizzling を含む）がこの後
    /// `viewDidAppear` の実装を差し替えると false になる。ラッパーが
    /// 元の実装をチェーンして呼んでいても、この値自体は false になりうる
    /// ため、汎用的な診断 API としては使わないこと。
    static var isMonitorSwizzlingActive: Bool {
        guard
            let installedImplementation,
            let method = class_getInstanceMethod(UIViewController.self, #selector(viewDidAppear(_:)))
        else {
            return false
        }
        return method_getImplementation(method) == installedImplementation
    }

    /// `viewDidAppear` の入れ替えをプロセス内で一度だけ行う。
    ///
    /// `stop()` では元に戻さない。他のライブラリが後から同じメソッドを
    /// swizzle している場合、戻す操作がそちらの実装を破壊するため。
    /// 有効・無効の制御は `ViewMonitor` 側の `started` フラグが担う。
    static func installMonitorSwizzlingIfNeeded() {
        guard swizzlingInstallCount == 0 else { return }
        guard
            let original = class_getInstanceMethod(
                UIViewController.self,
                #selector(viewDidAppear(_:))
            ),
            let replacement = class_getInstanceMethod(
                UIViewController.self,
                #selector(viewMonitor_viewDidAppear(animated:))
            )
        else {
            return
        }
        method_exchangeImplementations(original, replacement)
        installedImplementation = method_getImplementation(original)
        swizzlingInstallCount += 1
    }

    @objc
    func viewMonitor_viewDidAppear(animated: Bool) {
        // 入れ替え後はこの呼び出しが元の viewDidAppear を指す。
        viewMonitor_viewDidAppear(animated: animated)
        // ViewMonitor 自身の UI(InfoView が内包するホスティングコントローラ)も
        // viewDidAppear を発火させる。これを画面遷移として扱うと reload() が走り、
        // いま表示したばかりのオーバーレイを畳んだうえに、実行ボタンまで OFF の
        // 新品へ差し替えてしまう(「トグルを押しても ON にならない」症状)。
        guard !(self is MonitorInternalViewController) else {
            return
        }
        // isBeingPresented は viewDidAppear の時点でまだ true になっている。
        // モーダル提示(アラート等)を計測 UI で覆わないための判定に使う。
        ViewMonitor.detectedViewDidAppear(isBeingPresented: isBeingPresented)
    }
}
