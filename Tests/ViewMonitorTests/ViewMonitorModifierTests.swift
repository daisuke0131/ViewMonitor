import SwiftUI
import Testing
import UIKit
@testable import ViewMonitor

@Suite("View+ViewMonitor")
@MainActor
struct ViewMonitorModifierTests {

    @Test("viewMonitor モディファイアは appear 時に計測を開始する")
    func startsOnAppear() {
        // 他テストが起動したままでも成立するよう先に止めてから検証する。
        ViewMonitor.stop()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = UIHostingController(rootView: Color.clear.viewMonitor())
        window.makeKeyAndVisible()
        window.rootViewController?.view.layoutIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))

        #expect(ViewMonitor.isStartedForTesting)

        ViewMonitor.stop()
    }
}
