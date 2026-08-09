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

    /// SwiftUI 要素の検出を、外部のアクセシビリティクライアント無しで有効にする。
    ///
    /// iOS はアクセシビリティクライアント(VoiceOver / Accessibility Inspector /
    /// UI テスト)が接続している間しかアクセシビリティツリーを構築しないため、
    /// 何もしないと SwiftUI 要素は検出されない。このメソッドはプロセス内から
    /// ツリーの構築を有効化する。`ViewMonitor.start()` の前後どちらで呼んでもよい。
    ///
    /// 内部でプライベート API を使うため **DEBUG ビルド限定**。リリースビルドでは
    /// 実装ごとコンパイルから除外され、常に false を返す何もしないメソッドになる
    /// (バイナリにプライベート API のシンボル名文字列も残らない)。
    ///
    /// - Returns: 有効化できたら true。リリースビルドと、シンボルを解決できない
    ///   環境では false。
    @discardableResult
    public static func enableSwiftUIElementDetection() -> Bool {
        #if DEBUG
        return AccessibilityActivator.activate()
        #else
        return false
        #endif
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
        // button を強参照キャプチャすると button.onToggle → button の自己参照サイクルになり、
        // removeLauncherButton() は onToggle をクリアしないため reload() のたびに
        // 直前の実行ボタンがリークする。button も weak で受ける。
        button.onToggle = { [weak self, weak button] isSelected in
            guard let self, let rootView = self.rootView else {
                return
            }
            if isSelected {
                self.overlay.show(on: rootView)
                // SwiftUI 要素のボタンは rootView に直接addSubviewされるため、
                // show(on:) の後だと実行ボタンより前面に乗ってしまう。
                // 実行ボタン(停止操作)がタップやドラッグを奪われないよう最前面に戻す。
                if let button {
                    rootView.bringSubviewToFront(button)
                }
            } else {
                self.overlay.hide()
            }
        }
        rootView.addSubview(button)
        rootView.bringSubviewToFront(button)
        launcherButton = button
    }

    // MARK: - Testing seam

    /// テスト用: 起動済みかどうか。公開 API には含まれない。
    static var isStartedForTesting: Bool { shared.started }

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
