import Testing
import UIKit
@testable import ViewMonitor

@Suite("ViewMonitor lifecycle")
@MainActor
struct ViewMonitorLifecycleTests {

    @Test("stop すると実行ボタンがビュー階層から取り除かれる")
    func stopRemovesLauncherButtonFromHierarchy() {
        let container = UIView()
        ViewMonitor.start()

        // 画面遷移で実行ボタンが追加される状況を再現する。
        ViewMonitor.simulateLauncherButtonAttachedForTesting(to: container)
        #expect(container.subviews.contains { $0 is MonitorLauncherButton })

        ViewMonitor.stop()

        // stop() は started を false に戻すだけのキルスイッチであるべきで、
        // 実行ボタンが残っていると tap から overlay を再度開けてしまい、
        // 「stop 後は何も起きない」という前提が崩れる。
        #expect(!container.subviews.contains { $0 is MonitorLauncherButton })
    }
}
