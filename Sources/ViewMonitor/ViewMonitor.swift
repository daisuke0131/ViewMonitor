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
    /// 計測中(トグル ON)かどうか。実行ボタンの isSelected は reload() で
    /// ボタンごと作り直されて消えるため、状態はここが持つ。
    private var measuring = false

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
        shared.measuring = false
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
        reload(on: WindowProvider.keyWindow)
    }

    /// テスト用に rootView を注入できる本体。ユニットテストのバンドルには
    /// 接続済みの window scene が無く `WindowProvider.keyWindow` が常に nil に
    /// なるため、貼り直し先を差し替えられるようにしている。
    private func reload(on newRootView: UIView?) {
        overlay.hide()
        removeLauncherButton()
        rootView = newRootView
        addLauncherButton()
        // 計測中に reload が起きた(回転・プログラム起因の画面遷移。タップ起因の
        // 遷移はシールドが塞いでいる)場合は、OFF に戻さず新しい画面を
        // 再スキャンして計測を続ける。選択状態(赤枠・距離の参照)は旧画面の
        // ビューと結びついているため引き継がない。
        guard measuring, let launcherButton, let rootView else {
            return
        }
        launcherButton.isSelected = true
        overlay.show(on: rootView)
        rootView.bringSubviewToFront(launcherButton)
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
            self.measuring = isSelected
            if isSelected {
                self.overlay.show(on: rootView)
                // 計測ボタンは rootView に直接addSubviewされるため、
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

    /// テスト用: 画面遷移・回転相当の `reload()` を任意の rootView で実行する。
    /// 公開 API には含まれない。
    static func simulateReloadForTesting(on view: UIView) {
        shared.reload(on: view)
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
        // orientationDidChange はウィンドウのリサイズ完了前に届くため、
        // ここで即 reload すると旧 bounds のまま配置してしまう
        // (横→縦で実行ボタンが x=705 など画面外に出る)。次の runloop に
        // 遅らせ、リサイズ後のジオメトリで貼り直す。
        DispatchQueue.main.async { [weak self] in
            guard let self, self.started else {
                return
            }
            self.reload()
        }
    }
}
