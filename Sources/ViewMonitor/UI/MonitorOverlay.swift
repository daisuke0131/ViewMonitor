//
//  MonitorOverlay.swift
//  ViewMonitor
//

import UIKit

/// 計測用オーバーレイのライフサイクルを管理する。
/// 対象ビューの走査、オーバーレイの取り付けと取り外し、
/// InfoView の表示制御を担う。
@MainActor
final class MonitorOverlay: NSObject {

    private let configuration: MonitorConfiguration
    private let scanner: ViewHierarchyScanner

    private weak var rootView: UIView?
    private var infoView: InfoView?
    private var shieldView: MonitorShieldView?
    private var buttons: [MonitorButton] = []
    /// 計測のために userInteractionEnabled を一時的に有効化したビュー。
    /// hide() で元に戻す。
    private var forcedInteractionViews: [UIView] = []
    /// 直前に選択したボタン。距離計測の参照元。
    /// weak なので hide() / 画面遷移の reload でボタンが破棄されれば
    /// 自動的に nil に戻り、古い画面のビューとペアになることがない。
    private weak var lastSelectedButton: MonitorButton?

    /// 座標変換の基準ウィンドウ。show(on:) で受け取った rootView を基準にする。
    /// WindowProvider.keyWindow を都度引き直すと、iPad のマルチシーン環境で
    /// オーバーレイの取り付け先と foreground のシーンがずれたときに
    /// 誤ったウィンドウで変換してしまう。
    private var currentWindow: UIWindow? {
        rootView?.window ?? (rootView as? UIWindow)
    }

    init(configuration: MonitorConfiguration = .default, scanner: ViewHierarchyScanner? = nil) {
        self.configuration = configuration
        self.scanner = scanner ?? ViewHierarchyScanner(configuration: configuration)
        super.init()
    }

    /// オーバーレイを構築して表示する。
    /// 盾 → InfoView → 計測ボタンの順に追加し、盾が計測 UI の背面・
    /// アプリ本体の前面に入るようにする。
    func show(on rootView: UIView) {
        hide()
        self.rootView = rootView
        addShieldView(to: rootView)
        addInfoView(to: rootView)
        let targets = scanner.measurementTargets(in: rootView)
        for target in targets {
            addMonitorButton(for: target, rootView: rootView)
        }
        showAccessibilityNoticeIfNeeded(for: targets, rootView: rootView)
        // SwiftUI 要素のボタンは rootView に直接addSubviewするため、
        // infoView より後に追加されると重なり順で上に乗ってしまう。
        // ドラッグ用ジェスチャの奪い合いを防ぐため、追加後に最前面へ戻す。
        if let infoView {
            rootView.bringSubviewToFront(infoView)
        }
    }

    /// ホスティングビューがあるのにアクセシビリティ要素を1つも検出できなかった
    /// 場合、InfoView に案内を出す。iOS はアクセシビリティクライアント接続中しか
    /// ツリーを構築しないため、この状態は珍しくない。無言のままだと利用者には
    /// 不具合と区別がつかない(実際に「トグルが効かない」と報告された)。
    private func showAccessibilityNoticeIfNeeded(for targets: [MeasurementTarget], rootView: UIView) {
        let detectedAccessibilityElement = targets.contains { target in
            if case .accessibilityElement = target {
                return true
            }
            return false
        }
        guard !detectedAccessibilityElement, scanner.hasHostingView(in: rootView), let infoView else {
            return
        }
        infoView.update(rows: InfoRowBuilder.swiftUIDetectionUnavailableRows())
        infoView.isHidden = false
    }

    /// オーバーレイを取り除き、変更したビューの状態を元に戻す。
    func hide() {
        buttons.forEach { $0.removeFromSuperview() }
        buttons.removeAll()
        infoView?.removeFromSuperview()
        infoView = nil
        shieldView?.removeFromSuperview()
        shieldView = nil
        forcedInteractionViews.forEach { $0.isUserInteractionEnabled = false }
        forcedInteractionViews.removeAll()
        lastSelectedButton = nil
        rootView = nil
    }

    /// アプリ本体へのタッチを遮る盾を、計測 UI より先(=背面)に入れる。
    private func addShieldView(to rootView: UIView) {
        let shield = MonitorShieldView(frame: rootView.bounds)
        shield.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        shield.backgroundColor = .clear
        rootView.addSubview(shield)
        shieldView = shield
    }

    private func addInfoView(to rootView: UIView) {
        let size = rootView.bounds.size
        let infoView = InfoView(
            frame: CGRect(origin: CGPoint(x: size.width - InfoView.width - 20.0, y: 70.0), size: .zero)
        )
        infoView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        infoView.isHidden = true
        infoView.addGestureRecognizer(
            UIPanGestureRecognizer(target: self, action: #selector(drag(sender:)))
        )
        rootView.addSubview(infoView)
        rootView.bringSubviewToFront(infoView)
        self.infoView = infoView
    }

    private func addMonitorButton(for target: MeasurementTarget, rootView: UIView) {
        switch target {
        case .uiKitView(let view):
            let button = makeMonitorButton(for: target, frame: CGRect(origin: .zero, size: view.frame.size))
            if !view.isUserInteractionEnabled {
                forcedInteractionViews.append(view)
                view.isUserInteractionEnabled = true
            }
            view.addSubview(button)
        case .accessibilityElement(let info):
            guard let element = info.element else {
                return
            }
            // ViewMonitor は keyWindow を rootView として渡すため window 座標 = rootView 座標。
            // 対象の UIView が存在しないので rootView 直下に固定配置する(スクロール非追従)。
            let frame = ViewInspector.inspect(element: element, kind: info.kind, in: currentWindow).frameInWindow
            let button = makeMonitorButton(for: target, frame: frame)
            rootView.addSubview(button)
        }
    }

    private func makeMonitorButton(for target: MeasurementTarget, frame: CGRect) -> MonitorButton {
        let button = MonitorButton(frame: frame)
        let color = UIColor(monitorHex: configuration.overlayColorHex, alpha: configuration.overlayAlpha) ?? .green
        button.setBackgroundImage(.monitorSolidColor(color), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15.0)
        button.addTarget(self, action: #selector(select(sender:)), for: .touchUpInside)
        button.measurementTarget = target
        button.alpha = 0.2
        buttons.append(button)
        return button
    }

    /// 選択状態の切り替え。実行時はボタンの target-action からのみ呼ばれる。
    /// MonitorOverlayTests から呼べるよう internal にしている。
    @objc
    func select(sender: MonitorButton) {
        sender.isSelected.toggle()
        guard let infoView else {
            return
        }
        // 距離セクションを表示しているときだけ非 nil。青枠の維持対象。
        var referenceButton: MonitorButton?
        if sender.isSelected {
            infoView.isHidden = false
            let window = currentWindow
            let inspection = currentInspection(of: sender, in: window)
            let reference: ViewInspection? = {
                guard let last = lastSelectedButton, last !== sender else {
                    return nil
                }
                return referenceInspection(of: last, in: window)
            }()
            infoView.update(rows: InfoRowBuilder.rows(from: inspection, comparedTo: reference))
            sender.layer.borderWidth = 2.0
            sender.layer.borderColor = UIColor.red.cgColor
            if reference != nil {
                referenceButton = lastSelectedButton
                referenceButton?.isSelected = false
                referenceButton?.layer.borderWidth = 2.0
                referenceButton?.layer.borderColor = UIColor.systemBlue.cgColor
            }
            lastSelectedButton = sender
        }
        for other in buttons where other !== sender && other !== referenceButton {
            other.layer.borderWidth = 0.0
            other.isSelected = false
        }
    }

    @objc
    private func drag(sender: UIPanGestureRecognizer) {
        guard let view = sender.view, let container = view.superview else {
            return
        }
        let translation = sender.translation(in: container)
        view.center = CGPoint(x: view.center.x + translation.x, y: view.center.y + translation.y)
        sender.setTranslation(.zero, in: container)
    }

    /// ターゲットの現在値を計測する。要素が破棄されていれば nil。
    /// `select` 内のローカル変数 `inspection` と衝突しないよう current を冠する。
    private func currentInspection(of button: MonitorButton, in window: UIWindow?) -> ViewInspection? {
        switch button.measurementTarget {
        case .uiKitView(let view):
            return ViewInspector.inspect(view, in: window)
        case .accessibilityElement(let info):
            guard let element = info.element else {
                return nil
            }
            return ViewInspector.inspect(element: element, kind: info.kind, in: window)
        case nil:
            return nil
        }
    }

    /// 参照(距離計測の相手)の計測。取り付け先の window が現在の window と
    /// 一致するときだけ有効。画面遷移後の古いターゲットとペアにしない。
    private func referenceInspection(of button: MonitorButton, in window: UIWindow?) -> ViewInspection? {
        switch button.measurementTarget {
        case .uiKitView(let view):
            guard let referenceWindow = view.window, referenceWindow === window else {
                return nil
            }
            return ViewInspector.inspect(view, in: window)
        case .accessibilityElement(let info):
            guard let hostingWindow = info.hostingView?.window, hostingWindow === window,
                  let element = info.element else {
                return nil
            }
            return ViewInspector.inspect(element: element, kind: info.kind, in: window)
        case nil:
            return nil
        }
    }
}
