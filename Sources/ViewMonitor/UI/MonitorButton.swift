//
//  MonitorButton.swift
//  ViewMonitor
//

import UIKit

class MonitorButton: UIButton {

    var measurementTarget: MeasurementTarget?

    override init(frame: CGRect) {
        super.init(frame: frame)
        // UI テスト(XCUITest)から計測ボタンを特定するための識別子。
        accessibilityIdentifier = "ViewMonitor.monitorButton"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
