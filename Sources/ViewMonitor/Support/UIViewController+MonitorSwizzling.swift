//
//  UIViewController+MonitorSwizzling.swift
//  ViewMonitor
//

import UIKit

@MainActor
extension UIViewController {

    private static var swizzlingInstallCount = 0

    /// swizzling が適用された回数。奇数回でなければ検知が働かないため、
    /// 常に 1 であることをテストで保証する。
    static var monitorSwizzlingInstallCount: Int { swizzlingInstallCount }

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
                #selector(monitor_viewDidAppear(animated:))
            )
        else {
            return
        }
        method_exchangeImplementations(original, replacement)
        swizzlingInstallCount += 1
    }

    @objc
    func monitor_viewDidAppear(animated: Bool) {
        // 入れ替え後はこの呼び出しが元の viewDidAppear を指す。
        monitor_viewDidAppear(animated: animated)
        ViewMonitor.detectedViewDidAppear()
    }
}
