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
    /// 回転通知起因の reload が既に予約済みかどうか。1回の物理回転で
    /// 通知が複数回届くため、予約は1つに束ねる。
    private var pendingOrientationReload = false

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
    /// `isBeingPresented` はモーダル提示(アラート・シート等)による出現かどうか。
    static func detectedViewDidAppear(isBeingPresented: Bool = false) {
        guard shared.started else {
            return
        }
        shared.handleTransition(isBeingPresented: isBeingPresented, on: WindowProvider.keyWindow)
    }

    /// 画面遷移・回転に応じてオーバーレイと実行ボタンを貼り直す。
    /// モーダル提示のときは計測を終了する: シールドで塞げない遷移のうち、
    /// モーダル(エラーダイアログ等)を覆ってしまうと、その OK ボタンが
    /// 押せなくなるため。push 遷移や回転では計測を維持する。
    private func handleTransition(isBeingPresented: Bool, on newRootView: UIView?) {
        if isBeingPresented {
            launcherButton?.isSelected = false
        }
        reload(on: newRootView)
    }

    /// 画面が入れ替わったので、オーバーレイと実行ボタンを貼り直す。
    private func reload() {
        reload(on: WindowProvider.keyWindow)
    }

    /// テスト用に rootView を注入できる本体。ユニットテストのバンドルには
    /// 接続済みの window scene が無く `WindowProvider.keyWindow` が常に nil に
    /// なるため、貼り直し先を差し替えられるようにしている。
    private func reload(on newRootView: UIView?) {
        // 計測中かどうかは実行ボタンの isSelected から導出する。専用フラグを
        // 持つと、貼り直し先が見つからず実行ボタンを失った後も「計測中」が
        // 残り続け、後の遷移で何の表示も無いままシールドが復活してしまう。
        // ボタンはこの後作り直すので、先に読む。
        let keepMeasuring = launcherButton?.isSelected == true
        overlay.hide()
        removeLauncherButton()
        rootView = newRootView
        addLauncherButton()
        // 計測中に reload が起きた(回転・プログラム起因の画面遷移。タップ起因の
        // 遷移はシールドが塞いでいる)場合は、OFF に戻さず新しい画面を
        // 再スキャンして計測を続ける。選択状態(赤枠・距離の参照)は旧画面の
        // ビューと結びついているため引き継がない。
        guard keepMeasuring, let launcherButton, let rootView else {
            return
        }
        launcherButton.isSelected = true
        beginMeasuring(with: launcherButton, on: rootView)
    }

    /// オーバーレイを表示して計測状態に入る。トグル ON と reload の復元の
    /// 両方から使う共通手順。実行ボタン(停止操作)がタップやドラッグを
    /// 奪われないよう、計測 UI を貼った後に最前面へ戻す。
    private func beginMeasuring(with button: MonitorLauncherButton, on rootView: UIView) {
        overlay.show(on: rootView)
        rootView.bringSubviewToFront(button)
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
            if isSelected, let button {
                self.beginMeasuring(with: button, on: rootView)
            } else if isSelected {
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

    /// テスト用: viewDidAppear 検知相当の遷移を任意の rootView で実行する。
    /// 公開 API には含まれない。
    static func simulateTransitionForTesting(isBeingPresented: Bool, on view: UIView) {
        shared.handleTransition(isBeingPresented: isBeingPresented, on: view)
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
        // 1回の物理回転で通知は複数回届く(portrait → faceUp → landscape 等)。
        // 予約を1つに束ね、reload の連打による再スキャンとちらつきを防ぐ。
        guard started, !pendingOrientationReload else {
            return
        }
        pendingOrientationReload = true
        let windowBefore = WindowProvider.keyWindow
        let boundsBefore = windowBefore?.bounds
        // orientationDidChange はウィンドウのリサイズ完了前に届くため、
        // ここで即 reload すると旧 bounds のまま配置してしまう
        // (横→縦で実行ボタンが x=705 など画面外に出る)。次の runloop に
        // 遅らせ、リサイズ後のジオメトリで貼り直す。
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }
            self.pendingOrientationReload = false
            guard self.started else {
                return
            }
            // faceUp / faceDown / 上下反転など、インターフェイスが回転せず
            // ジオメトリが変わらない向きの変化では貼り直さない。reload は
            // 選択状態(赤枠・距離の参照・InfoView の表示)を破棄するため、
            // 見た目が何も変わらないのに計測内容だけ消えてしまう。
            let window = WindowProvider.keyWindow
            if let window, window === windowBefore, window.bounds == boundsBefore {
                return
            }
            self.reload()
        }
    }
}
