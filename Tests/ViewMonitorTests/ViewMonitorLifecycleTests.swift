import Testing
import UIKit
@testable import ViewMonitor

/// 既定のスキャナ (`ViewHierarchyScanner.isDefaultHostingView`) はクラス名の
/// 文字列前方一致だけで SwiftUI のホスティングビューを判定する。
/// 実際に `UIHostingController` をこのテストバンドル(ホストアプリを持たない
/// ユニットテスト実行環境)内で window に取り付けずに使うと、SwiftUI 側の
/// オフスクリーン計測が `UIViewController.viewDidAppear` を発火させることがあり、
/// ViewMonitor が起動中はこれを画面遷移とみなして無関係に `reload()` してしまう
/// (このテストバンドルでは `WindowProvider.keyWindow` が常に nil のため、
/// `reload()` は実行ボタンを取り除いたまま再アタッチできず消えてしまう)。
/// 型名だけこの規約に合わせた軽量ダミーを使い、本物の `UIHostingController` を
/// 経由せずに既定スキャナの検出経路を再現する。
private final class _UIHostingViewProbe: UIView {}

// ViewMonitor.shared はプロセス内で共有される単一のインスタンスのため、
// テストを並行実行すると一方の stop() がもう一方の実行ボタンを
// ビュー階層から奪ってしまう。.serialized で直列実行を強制する。
@Suite("ViewMonitor lifecycle", .serialized)
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

    @Test("SwiftUI 要素と重なっていても実行ボタンは最前面に留まる")
    func launcherStaysInFrontOfOverlappingAccessibilityButton() throws {
        // 実行ボタンは reload() で先に addSubview されるため、対策前は
        // overlay.show(on:) が後から rootView 直下に追加する SwiftUI 要素の
        // ボタンに前面を奪われ、停止タップやドラッグが要素側に吸われていた。
        //
        // ViewMonitor.start() は呼ばない: simulateLauncherButtonAttachedForTesting は
        // started 状態に依存せず実行ボタンを取り付けられる。start() を呼ぶと
        // viewDidAppear の swizzling が有効化され、addInfoView() 内で
        // UIHostingController.sizeThatFits が誘発する viewDidAppear が
        // 無関係な reload() を引き起こしてしまう(このテストバンドルには
        // 接続中の window scene が無いため reload() が実行ボタンを再アタッチできない)。
        ViewMonitor.stop()

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))

        // 既定のスキャナ(_UIHostingView プレフィックス判定)で検出されることを確認する。
        let host = _UIHostingViewProbe(frame: CGRect(x: 200, y: 0, width: 120, height: 100))
        #expect(ViewHierarchyScanner.isDefaultHostingView(host))
        let element = UIAccessibilityElement(accessibilityContainer: host)
        element.isAccessibilityElement = true
        element.accessibilityTraits = .staticText
        // 実行ボタンは右上 (x: 228, y: 20, w: 72, h: 49) 付近に置かれるので、
        // それと重なる領域に要素を置く。
        element.accessibilityFrame = CGRect(x: 220, y: 10, width: 100, height: 80)
        host.accessibilityElements = [element]
        window.addSubview(host)

        ViewMonitor.simulateLauncherButtonAttachedForTesting(to: window)
        let launcher = try #require(window.subviews.compactMap { $0 as? MonitorLauncherButton }.first)

        // 実行ボタンの tap から呼ばれる内部シームを直接発火させる。
        launcher.onToggle?(true)

        let elementButton = try #require(window.subviews.compactMap { $0 as? MonitorButton }.first)
        let launcherIndex = try #require(window.subviews.firstIndex { $0 === launcher })
        let elementButtonIndex = try #require(window.subviews.firstIndex { $0 === elementButton })
        #expect(launcherIndex > elementButtonIndex)

        // 後始末: overlay を閉じる。実行ボタン自体は window ごと ARC で解放される。
        launcher.onToggle?(false)
    }
}
