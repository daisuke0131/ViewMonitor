//
//  MonitorLauncherButton.swift
//  ViewMonitor
//

import UIKit

/// 計測の開始・終了を切り替える実行ボタン。
/// 画面上をドラッグで移動できる。
@MainActor
final class MonitorLauncherButton: UIButton {

    static let size = CGSize(width: 72.0, height: 49.0)
    static let margin: CGFloat = 20.0

    /// 選択状態が切り替わったときに呼ばれる。
    var onToggle: ((Bool) -> Void)?

    /// safe area の内側にボタンを右上寄せで配置する原点を返す。
    static func origin(inBounds bounds: CGRect, safeAreaInsets insets: UIEdgeInsets) -> CGPoint {
        let x = bounds.maxX - insets.right - size.width - margin
        let y = bounds.minY + insets.top + margin
        return CGPoint(x: max(bounds.minX + insets.left + margin, x), y: y)
    }

    init(origin: CGPoint) {
        super.init(frame: CGRect(origin: origin, size: Self.size))
        // UI テスト(XCUITest)から実行ボタンを特定するための識別子。
        accessibilityIdentifier = "ViewMonitor.launcher"
        setBackgroundImage(ViewMonitorAsset.button ?? .monitorSolidColor(.black), for: .normal)
        setBackgroundImage(ViewMonitorAsset.buttonSelected ?? .monitorSolidColor(.red), for: .selected)
        addTarget(self, action: #selector(toggle), for: .touchUpInside)
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(drag(sender:))))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func toggle() {
        isSelected.toggle()
        onToggle?(isSelected)
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
