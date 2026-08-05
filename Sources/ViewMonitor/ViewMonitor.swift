//
//  ViewMonitor.swift
//  ViewMonitor
//

import UIKit

/// ビューの位置やサイズを画面上で計測するデバッグ用ツール。
///
///     ViewMonitor.start()
///
/// 実行後、画面右上に表示されるボタンから計測を開始できる。
@MainActor
public final class ViewMonitor: NSObject {

    static let shared = ViewMonitor()

    private let overlay = MonitorOverlay()
    private var launcherButton: MonitorLauncherButton?
    private weak var rootView: UIView?
    private var started = false

    /// 計測を開始する。実行ボタンが画面に表示される。
    public static func start() {
        guard !shared.started else {
            return
        }
        UIViewController.installMonitorSwizzlingIfNeeded()
        shared.startObservingOrientation()
        shared.started = true
        shared.reload()
    }

    /// 計測を終了し、追加した表示をすべて取り除く。
    public static func stop() {
        guard shared.started else {
            return
        }
        shared.overlay.hide()
        shared.removeLauncherButton()
        shared.stopObservingOrientation()
        shared.started = false
    }

    /// `viewDidAppear` の swizzling から呼ばれる。
    static func detectedViewDidAppear() {
        guard shared.started else {
            return
        }
        shared.reload()
    }

    /// 画面が入れ替わったので、オーバーレイと実行ボタンを貼り直す。
    private func reload() {
        overlay.hide()
        removeLauncherButton()
        rootView = WindowProvider.keyWindow
        addLauncherButton()
    }

    private func addLauncherButton() {
        removeLauncherButton()
        guard let rootView else {
            return
        }
        let origin = MonitorLauncherButton.origin(
            inBounds: rootView.bounds,
            safeAreaInsets: rootView.safeAreaInsets
        )
        let button = MonitorLauncherButton(origin: origin)
        button.onToggle = { [weak self] isSelected in
            guard let self, let rootView = self.rootView else {
                return
            }
            if isSelected {
                self.overlay.show(on: rootView)
            } else {
                self.overlay.hide()
            }
        }
        rootView.addSubview(button)
        rootView.bringSubviewToFront(button)
        launcherButton = button
    }

    // MARK: - Testing seam

    /// テスト用: `rootView` に任意の `UIView` を注入し、実行ボタンを追加した状態を再現する。
    /// ユニットテストのバンドルには接続済みの window scene が無く
    /// `WindowProvider.keyWindow` が常に nil になるため、`detectedViewDidAppear()`
    /// 経由では実ビュー階層上での追加・削除を検証できない。
    /// 公開 API には含まれない。
    static func simulateLauncherButtonAttachedForTesting(to view: UIView) {
        shared.rootView = view
        shared.addLauncherButton()
    }

    private func removeLauncherButton() {
        launcherButton?.removeFromSuperview()
        launcherButton = nil
    }

    private func startObservingOrientation() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(orientationChanged),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    private func stopObservingOrientation() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    @objc
    private func orientationChanged() {
        guard started else {
            return
        }
        reload()
    }
}
