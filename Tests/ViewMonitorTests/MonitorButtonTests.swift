import Testing
import UIKit
@testable import ViewMonitor

@Suite("MonitorButton")
@MainActor
struct MonitorButtonTests {

    @Test("targetView に設定したビューをそのまま保持する")
    func retainsTargetView() {
        let button = MonitorButton()
        let target = UIView()

        button.targetView = target

        #expect(button.targetView === target)
    }

    @Test("targetView の初期値は nil である")
    func targetViewIsNilByDefault() {
        let button = MonitorButton()

        #expect(button.targetView == nil)
    }
}
