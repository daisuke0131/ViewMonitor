import Testing
import UIKit
@testable import ViewMonitor

@Suite("swizzling")
@MainActor
struct SwizzlingTests {

    @Test("start と stop を繰り返しても swizzling の適用は1回だけ")
    func installsSwizzlingOnlyOnce() {
        ViewMonitor.start()
        ViewMonitor.stop()
        ViewMonitor.start()
        ViewMonitor.stop()

        // 2回適用されると入れ替えが元に戻り、画面遷移の検知が止まる。
        #expect(UIViewController.monitorSwizzlingInstallCount == 1)
    }

    @Test("start 後に swizzling が適用されている")
    func installsSwizzlingOnStart() {
        ViewMonitor.start()
        defer { ViewMonitor.stop() }

        #expect(UIViewController.monitorSwizzlingInstallCount == 1)
    }
}
