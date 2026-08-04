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

    @Test("stop で入れ替えを戻さないため、繰り返しても viewDidAppear は常にラッパーを指す")
    func viewDidAppearStaysSwizzledAcrossStartStopCycles() {
        // monitorSwizzlingInstallCount は「適用試行が成功した回数」を数えるだけで、
        // stop() が万が一 un-swizzle を再導入しても2回目以降の installMonitorSwizzlingIfNeeded()
        // は早期リターンして 1 のまま動かない。実際に viewDidAppear が今どちらを
        // 指しているかを見る isMonitorSwizzlingActive でこの回帰を検知する。
        //
        // 毎回の stop() 直後に assert すること。最後にまとめて1回だけ assert すると、
        // stop() に偶数回だけ un-swizzle を再導入した場合に元へ戻る組み合わせが
        // 相殺してしまい、実際には途中で検知が壊れていても見逃してしまう。
        ViewMonitor.start()
        ViewMonitor.stop()
        #expect(UIViewController.isMonitorSwizzlingActive)

        ViewMonitor.start()
        ViewMonitor.stop()
        #expect(UIViewController.isMonitorSwizzlingActive)
    }
}
