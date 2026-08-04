import Testing
import UIKit
@testable import ViewMonitor

@Suite("ViewMonitor lifecycle")
@MainActor
struct ViewMonitorLifecycleTests {

    @Test("stop すると実行ボタンがビュー階層から取り除かれる")
    func stopRemovesExecuteButtonFromHierarchy() {
        let container = UIView()
        ViewMonitor.start()

        // 画面遷移で実行ボタンが追加される状況を再現する。
        ViewMonitor.simulateExecuteButtonAttachedForTesting(to: container)
        #expect(container.subviews.contains { $0 is MonitorButton })

        ViewMonitor.stop()

        // stop() は started を false に戻すだけのキルスイッチであるべきで、
        // 実行ボタンが残っていると tap から execute() が再度呼べてしまい、
        // 「stop 後は何も起きない」という前提が崩れる。
        #expect(!container.subviews.contains { $0 is MonitorButton })
    }
}
