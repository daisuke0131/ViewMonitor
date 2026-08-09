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
        // started 状態に依存せず実行ボタンを取り付けられるため、この検証には不要。
        // (かつては addInfoView() 内の UIHostingController が誘発する viewDidAppear で
        // reload() が走ってしまうため start() を避けていたが、内部 VC を
        // MonitorInternalViewController として検知対象から外したので解消済み。)
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

    @Test("自前の InfoView が発火させる viewDidAppear で計測状態が畳まれない")
    func internalHostingControllerAppearanceKeepsMonitoringOn() throws {
        // InfoView は描画を UIHostingController に委譲しているため、overlay を
        // 表示すると自身の viewDidAppear が発火する。これを画面遷移として扱うと
        // reload() が走り、いま開いたばかりのオーバーレイを自分で畳んだうえに
        // 実行ボタンまで OFF の新品へ差し替えてしまう(実機では「トグルを押しても
        // ON にならない」という症状になる)。自前の VC は検知対象から外す。
        ViewMonitor.stop()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))

        // swizzling を有効にするため start() を通す。
        ViewMonitor.start()
        ViewMonitor.simulateLauncherButtonAttachedForTesting(to: window)
        let launcher = try #require(window.subviews.compactMap { $0 as? MonitorLauncherButton }.first)

        launcher.isSelected = true
        launcher.onToggle?(true)
        let infoView = try #require(window.subviews.compactMap { $0 as? InfoView }.first)

        // InfoView が内包するホスティングコントローラを responder chain から取り出す。
        // SwiftUI が中間レスポンダ(UIKitKeyPressResponder)を挟むため、
        // next を1つ辿るだけでは届かない。最初の UIViewController まで遡る。
        let hostedView = try #require(infoView.subviews.first)
        var responder: UIResponder? = hostedView.next
        while let current = responder, !(current is UIViewController) {
            responder = current.next
        }
        let hostingController = try #require(responder as? UIViewController)
        hostingController.viewDidAppear(false)

        // オーバーレイも実行ボタンもそのままであること。
        #expect(window.subviews.contains { $0 === infoView })
        #expect(window.subviews.contains { $0 === launcher })
        #expect(launcher.isSelected)

        launcher.onToggle?(false)
        ViewMonitor.stop()
    }

    @Test("計測中に reload が起きても ON を維持して新画面を再スキャンする")
    func reloadKeepsMeasuringAndRescans() throws {
        // 回転やプログラム起因の画面遷移で reload() が走ると、従来は実行ボタンが
        // OFF の新品に差し替わり計測が無言で終わっていた。シールドがタップ起因の
        // 遷移を塞いだ今、残るこの2経路でも計測を維持し、新しい画面を
        // 再スキャンして貼り直す。
        ViewMonitor.stop()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window.addSubview(UILabel(frame: CGRect(x: 16, y: 100, width: 100, height: 20)))
        ViewMonitor.simulateLauncherButtonAttachedForTesting(to: window)
        let launcher = try #require(window.subviews.compactMap { $0 as? MonitorLauncherButton }.first)
        launcher.isSelected = true
        launcher.onToggle?(true)
        #expect(window.subviews.contains { $0 is MonitorButton })

        // 回転・画面遷移相当。次の画面には別の対象がある。
        let nextWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 480, height: 320))
        nextWindow.addSubview(UIImageView(frame: CGRect(x: 10, y: 10, width: 60, height: 40)))
        ViewMonitor.simulateReloadForTesting(on: nextWindow)

        let newLauncher = try #require(nextWindow.subviews.compactMap { $0 as? MonitorLauncherButton }.first)
        #expect(newLauncher.isSelected, "reload で計測が OFF に戻ってしまった")
        #expect(nextWindow.subviews.contains { $0 is MonitorButton }, "新画面が再スキャンされていない")
        // 実行ボタン(停止操作)は再スキャン後も最前面。
        let launcherIndex = try #require(nextWindow.subviews.firstIndex { $0 === newLauncher })
        #expect(launcherIndex == nextWindow.subviews.count - 1)

        newLauncher.onToggle?(false)
        ViewMonitor.stop()
    }

    @Test("モーダル提示の遷移では計測を終了する(ダイアログを覆わない)")
    func modalPresentationCancelsMeasuring() throws {
        // モーダル(エラーダイアログ等)はシールドで塞げない遷移で、計測を
        // 維持するとシールドがダイアログの上に乗り、OK ボタンが押せなくなる。
        // モーダル提示だけは従来どおり計測を終了する。
        ViewMonitor.stop()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window.addSubview(UILabel(frame: CGRect(x: 16, y: 100, width: 100, height: 20)))
        ViewMonitor.simulateLauncherButtonAttachedForTesting(to: window)
        let launcher = try #require(window.subviews.compactMap { $0 as? MonitorLauncherButton }.first)
        launcher.isSelected = true
        launcher.onToggle?(true)

        let dialogWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        dialogWindow.addSubview(UILabel(frame: CGRect(x: 16, y: 100, width: 100, height: 20)))
        ViewMonitor.simulateTransitionForTesting(isBeingPresented: true, on: dialogWindow)

        let newLauncher = try #require(dialogWindow.subviews.compactMap { $0 as? MonitorLauncherButton }.first)
        #expect(!newLauncher.isSelected, "モーダル提示でも計測が維持されてしまった")
        #expect(!dialogWindow.subviews.contains { $0 is MonitorShieldView }, "シールドがダイアログを覆っている")
        ViewMonitor.stop()
    }

    @Test("push 相当の遷移(モーダルでない)では計測を維持する")
    func nonModalTransitionKeepsMeasuring() throws {
        ViewMonitor.stop()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        ViewMonitor.simulateLauncherButtonAttachedForTesting(to: window)
        let launcher = try #require(window.subviews.compactMap { $0 as? MonitorLauncherButton }.first)
        launcher.isSelected = true
        launcher.onToggle?(true)

        let nextWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        ViewMonitor.simulateTransitionForTesting(isBeingPresented: false, on: nextWindow)

        let newLauncher = try #require(nextWindow.subviews.compactMap { $0 as? MonitorLauncherButton }.first)
        #expect(newLauncher.isSelected)
        newLauncher.onToggle?(false)
        ViewMonitor.stop()
    }

    @Test("計測 OFF なら reload しても OFF のまま")
    func reloadStaysOffWhenNotMeasuring() throws {
        ViewMonitor.stop()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        ViewMonitor.simulateLauncherButtonAttachedForTesting(to: window)

        let nextWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        nextWindow.addSubview(UILabel(frame: CGRect(x: 16, y: 100, width: 100, height: 20)))
        ViewMonitor.simulateReloadForTesting(on: nextWindow)

        let launcher = try #require(nextWindow.subviews.compactMap { $0 as? MonitorLauncherButton }.first)
        #expect(!launcher.isSelected)
        #expect(!nextWindow.subviews.contains { $0 is MonitorButton })
        ViewMonitor.stop()
    }

    @Test("stop すると計測中状態もリセットされる")
    func stopClearsMeasuringState() throws {
        // stop() 後に start() し直したとき、前回の計測中状態が残っていると
        // 最初の reload でいきなりオーバーレイが開いてしまう。
        // stop() は started ガードを持つため、実運用どおり start() を通す。
        ViewMonitor.stop()
        ViewMonitor.start()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        ViewMonitor.simulateLauncherButtonAttachedForTesting(to: window)
        let launcher = try #require(window.subviews.compactMap { $0 as? MonitorLauncherButton }.first)
        launcher.isSelected = true
        launcher.onToggle?(true)

        ViewMonitor.stop()

        let nextWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        ViewMonitor.simulateReloadForTesting(on: nextWindow)
        let newLauncher = try #require(nextWindow.subviews.compactMap { $0 as? MonitorLauncherButton }.first)
        #expect(!newLauncher.isSelected)
        ViewMonitor.stop()
    }

    @Test("画面遷移で実行ボタンが差し替わると直前のボタンが解放される")
    func replacedLauncherButtonIsDeallocated() throws {
        // onToggle クロージャが自身の button を強参照キャプチャすると
        // button → onToggle → button の自己参照サイクルになる。
        // removeLauncherButton() は onToggle をクリアしないため、reload()
        // (viewDidAppear や画面回転のたびに呼ばれる)を経由するたびに
        // 直前の実行ボタンがリークしてしまう。
        ViewMonitor.stop()
        weak var leaked: MonitorLauncherButton?

        // ローカル変数(window / launcher)を内側の関数に閉じ込め、
        // 弱参照だけを外側に残す。UIKit のオブジェクトは autoreleasepool 越しに
        // 解放されることがあるため、確認前に明示的にプールを回す。
        func attachAndToggleOnce() throws {
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
            ViewMonitor.simulateLauncherButtonAttachedForTesting(to: window)
            let launcher = try #require(window.subviews.compactMap { $0 as? MonitorLauncherButton }.first)
            leaked = launcher
            // onToggle が実際にタップされてクロージャ内のキャプチャが働いた状態を再現する。
            launcher.onToggle?(true)
            launcher.onToggle?(false)
        }
        try autoreleasepool {
            try attachAndToggleOnce()
        }

        // 画面遷移相当: addLauncherButton() が removeLauncherButton() 経由で
        // 直前のボタンを新しいボタンに差し替える。removeFromSuperview() 自体が
        // 内部で autorelease するオブジェクトを生む可能性があるため、
        // この呼び出しも autoreleasepool で包んでから弱参照を確認する。
        autoreleasepool {
            let nextWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
            ViewMonitor.simulateLauncherButtonAttachedForTesting(to: nextWindow)
        }

        #expect(leaked == nil)

        ViewMonitor.stop()
    }
}
