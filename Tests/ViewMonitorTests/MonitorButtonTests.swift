import Testing
import UIKit
@testable import ViewMonitor

@Suite("MonitorButton")
@MainActor
struct MonitorButtonTests {

    @Test("measurementTarget に設定したビューをそのまま保持する")
    func retainsMeasurementTarget() throws {
        let button = MonitorButton()
        let target = UIView()

        button.measurementTarget = .uiKitView(target)

        guard case .uiKitView(let held) = try #require(button.measurementTarget) else {
            Issue.record("uiKitView ではない")
            return
        }
        #expect(held === target)
    }

    @Test("measurementTarget の初期値は nil である")
    func measurementTargetIsNilByDefault() {
        let button = MonitorButton()

        #expect(button.measurementTarget == nil)
    }
}
