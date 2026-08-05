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
    private var buttons: [MonitorButton] = []
    /// 計測のために userInteractionEnabled を一時的に有効化したビュー。
    /// hide() で元に戻す。
    private var forcedInteractionViews: [UIView] = []

    init(configuration: MonitorConfiguration = .default) {
        self.configuration = configuration
        self.scanner = ViewHierarchyScanner(configuration: configuration)
        super.init()
    }

    /// オーバーレイを構築して表示する。
    func show(on rootView: UIView) {
        hide()
        self.rootView = rootView
        addInfoView(to: rootView)
        for view in scanner.targets(in: rootView) {
            addMonitorButton(on: view)
        }
    }

    /// オーバーレイを取り除き、変更したビューの状態を元に戻す。
    func hide() {
        buttons.forEach { $0.removeFromSuperview() }
        buttons.removeAll()
        infoView?.removeFromSuperview()
        infoView = nil
        forcedInteractionViews.forEach { $0.isUserInteractionEnabled = false }
        forcedInteractionViews.removeAll()
        rootView = nil
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

    private func addMonitorButton(on view: UIView) {
        let button = MonitorButton(frame: CGRect(origin: .zero, size: view.frame.size))
        let color = UIColor(monitorHex: configuration.overlayColorHex, alpha: configuration.overlayAlpha) ?? .green
        button.setBackgroundImage(.monitorSolidColor(color), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15.0)
        button.addTarget(self, action: #selector(select(sender:)), for: .touchUpInside)
        button.targetView = view
        button.alpha = 0.2
        buttons.append(button)

        if !view.isUserInteractionEnabled {
            forcedInteractionViews.append(view)
            view.isUserInteractionEnabled = true
        }
        view.addSubview(button)
    }

    @objc
    private func select(sender: MonitorButton) {
        sender.isSelected.toggle()
        guard let infoView else {
            return
        }
        if sender.isSelected {
            infoView.isHidden = false
            // 座標変換は show(on:) で受け取った rootView を基準にする。
            // WindowProvider.keyWindow を都度引き直すと、iPad の
            // マルチシーン環境でオーバーレイの取り付け先と foreground の
            // シーンがずれたときに誤ったウィンドウで変換してしまう。
            let window = rootView?.window ?? (rootView as? UIWindow)
            let inspection = sender.targetView.map { ViewInspector.inspect($0, in: window) }
            infoView.update(rows: InfoRowBuilder.rows(from: inspection))
            sender.layer.borderWidth = 2.0
            sender.layer.borderColor = UIColor.red.cgColor
        }
        for other in buttons where other !== sender {
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
}
