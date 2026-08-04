//
//  ViewMonitor.swift
//  ViewMonitor
//

import UIKit
import Foundation

@MainActor
public final class ViewMonitor: NSObject {

    static let shared = ViewMonitor()

    /** target rootView */
    private var rootView: UIView?

    // show target view detail
    private var infoView: InfoView?

    private var executeButton: MonitorButton?

    /** retain my objects */
    private var buttons: [UIButton] = [UIButton]()

    private var started: Bool = false

    /* userInteractionEnabled */
    private var enabledViews: [UIView] = [UIView]()

    private let scanner = ViewHierarchyScanner()

    public static func start() {
        guard !shared.started else { return }
        UIViewController.installMonitorSwizzlingIfNeeded()
        shared.setNotification()
        shared.started = true
    }

    public static func stop() {
        guard shared.started else { return }
        shared.terminate()
        shared.deleteExecuteButton()
        shared.removeNotification()
        shared.started = false
    }

    // MARK: - Testing seam

    /// テスト用: `rootView` に任意の `UIView` を注入し、実行ボタンを追加した状態を再現する。
    /// ユニットテストのバンドルには接続済みの window scene が無く `WindowProvider.keyWindow`
    /// が常に nil になるため、`detectedViewDidAppear()` 経由では実ビュー階層上での
    /// 追加・削除を検証できない。この関数はその代わりに使う最小限のフックで、
    /// 公開 API には含まれない。
    static func simulateExecuteButtonAttachedForTesting(to view: UIView) {
        shared.rootView = view
        shared.addExecuteButton()
    }

    private func execute() {
        addInfoView()
        analyzeAllViews()
    }

    private func terminate() {
        deleteAllMonitorViews()
        deleteInfoView()
        resetAllInteractionEnabled()
    }

    private func deleteExecuteButton() {
        if let executeButton = executeButton {
            executeButton.removeFromSuperview()
            self.executeButton = nil
        }
    }

    private func deleteInfoView() {
        if let infoView = infoView {
            infoView.removeFromSuperview()
            self.infoView = nil
        }
    }

    private func setNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.orientationChanged(notification:)),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    private func removeNotification() {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    @objc private func orientationChanged(notification: NSNotification) {
        if started {
            deleteInfoView()
            deleteExecuteButton()
            deleteAllMonitorViews()
            resetAllInteractionEnabled()
            rootView = WindowProvider.keyWindow
            addExecuteButton()
        }
    }

    /// `viewDidAppear` の swizzling から呼ばれる。
    static func detectedViewDidAppear() {
        guard shared.started else { return }
        shared.deleteInfoView()
        shared.deleteExecuteButton()
        shared.deleteAllMonitorViews()
        shared.resetAllInteractionEnabled()
        shared.rootView = WindowProvider.keyWindow
        shared.addExecuteButton()
        shared.addInfoView()
    }

    private func addExecuteButton() {
        guard let executeButton = executeButton else {
            let deviceSize: CGSize = rootView?.bounds.size ?? .zero
            self.executeButton = MonitorButton(frame: CGRect(x: deviceSize.width - 100.0, y: 20.0, width: 72.0, height: 49.0))
            self.executeButton?.setBackgroundImage(
                ViewMonitorAsset.button ?? .monitorSolidColor(.black),
                for: .normal
            )
            self.executeButton?.setBackgroundImage(
                ViewMonitorAsset.buttonSelected ?? .monitorSolidColor(.red),
                for: .selected
            )
            self.executeButton?.addTarget(self, action: #selector(self.manualExecute(sender:)), for: UIControl.Event.touchUpInside)

            let pan = UIPanGestureRecognizer(target: self, action: #selector(self.dragEvent(sender:)))
            self.executeButton?.addGestureRecognizer(pan)
            if let executeButton = self.executeButton {
                rootView?.addSubview(executeButton)
                rootView?.bringSubviewToFront(executeButton)
            }
            return
        }
        rootView?.addSubview(executeButton)
        rootView?.bringSubviewToFront(executeButton)
    }

    @objc private func dragEvent(sender: UIPanGestureRecognizer) {
        let diff = sender.translation(in: rootView)
        let center = CGPoint(x: sender.view!.center.x + diff.x, y: sender.view!.center.y + diff.y)
        sender.view?.center = center
        sender.setTranslation(CGPoint.zero, in: rootView)
    }

    // execute
    @objc func manualExecute(sender: MonitorButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            execute()
        } else {
            terminate()
        }
    }

    // make 100 * 100 information view
    // have to set tag to reject.
    private func addInfoView() {
        let deviceSize: CGSize = rootView?.bounds.size ?? .zero
        self.infoView = InfoView(frame: CGRect(x: deviceSize.width - 220.0, y: 70.0, width: 200.0, height: 180.0))
        let color = UIColor.black
        let alphaColor = color.withAlphaComponent(0.6)
        self.infoView!.backgroundColor = alphaColor
        self.infoView!.isHidden = true
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.dragEvent(sender:)))
        self.infoView!.addGestureRecognizer(pan)
        rootView?.addSubview(self.infoView!)
        rootView?.bringSubviewToFront(self.infoView!)
    }

    private func deleteAllMonitorViews() {
        _ = buttons.map { $0.removeFromSuperview() }
        buttons.removeAll(keepingCapacity: false)
    }

    private func analyzeAllViews() {
        guard let rootView else { return }
        for view in scanner.targets(in: rootView) {
            drawViewOn(view: view)
        }
    }

    private func drawViewOn(view: UIView) {
        let button = MonitorButton(frame: CGRect(x: 0.0, y: 0.0, width: view.frame.size.width, height: view.frame.size.height))
        button.setBackgroundImage(
            .monitorSolidColor(UIColor(monitorHex: "#7ED321", alpha: 0.7) ?? .green),
            for: .normal
        )
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
        button.addTarget(self, action: #selector(self.openEditor(sender:)), for: UIControl.Event.touchUpInside)
        button.targetView = view
        button.alpha = 0.2
        buttons.append(button)
        if !view.isUserInteractionEnabled {
            enabledViews.append(view)
            view.isUserInteractionEnabled = true
        }
        view.addSubview(button)
    }

    private func resetAllInteractionEnabled() {
        _ = enabledViews.map { $0.isUserInteractionEnabled = false }
        enabledViews.removeAll(keepingCapacity: false)
    }

    // editor to monitor view
    @objc func openEditor(sender: MonitorButton) {
        sender.isSelected = !sender.isSelected
        if let infoView = infoView {
            if sender.isSelected {
                infoView.isHidden = false
                infoView.targetView = sender.targetView
                sender.layer.borderWidth = 2.0
                sender.layer.borderColor = UIColor.red.cgColor
            }
            _ = buttons.filter { $0 !== sender }.map { $0.layer.borderWidth = 0.0; $0.isSelected = false }
        }
    }
}
