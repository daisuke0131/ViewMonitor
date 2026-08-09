import Testing
import UIKit
@testable import ViewMonitor

/// 計測中のタッチ遮断。
/// 計測ボタンに覆われていない領域へのタップやスクロールがアプリ側に届くと、
/// ボタンの誤発火だけでなく、画面遷移で計測状態ごと破棄されてしまう
/// (遷移検知の reload が実行ボタンを OFF の新品に差し替える)。
/// 計測中はアプリ本体へのタッチを遮り、ViewMonitor 自身の UI へのタッチ
/// だけを通す。
@Suite("MonitorOverlay input shield")
@MainActor
struct MonitorShieldTests {

    private func makeWindow() -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        // 生成直後の UIWindow は hidden で、hitTest が常に nil を返す。
        // ヒットテストの検証ができるよう表示状態にする(シーンへの取り付けは不要)。
        window.isHidden = false
        return window
    }

    private func shield(in root: UIView) -> UIView? {
        root.subviews.first { $0 is MonitorShieldView }
    }

    @Test("表示中はアプリへのタッチを遮る盾が入り、hide で取り除かれる")
    func showAddsShieldAndHideRemovesIt() throws {
        let window = makeWindow()
        let overlay = MonitorOverlay()

        overlay.show(on: window)
        let shieldView = try #require(shield(in: window))
        #expect(shieldView.frame == window.bounds)

        overlay.hide()
        #expect(shield(in: window) == nil)
    }

    @Test("計測ボタンの無い領域へのタッチは盾が吸収する")
    func shieldAbsorbsTouchesOverAppContent() throws {
        let window = makeWindow()
        let label = UILabel(frame: CGRect(x: 16, y: 100, width: 100, height: 20))
        window.addSubview(label)
        let overlay = MonitorOverlay()
        overlay.show(on: window)

        // ラベル(計測ボタン)から離れた何もない領域。
        let hit = window.hitTest(CGPoint(x: 250, y: 400), with: nil)

        #expect(hit is MonitorShieldView)
        overlay.hide()
    }

    @Test("UIKit 対象の計測ボタンも盾より前面に付き、タップが届く")
    func uiKitMonitorButtonsSitAboveShield() throws {
        // 対象ビューの subview としてボタンを付けると、盾との間に SwiftUI の
        // ホスティングビューが挟まる。_UIHostingView の hitTest は純粋関数では
        // なく、同じ点への連続呼び出しで異なる結果を返すことがある(実機で
        // 1回目は配下の計測ボタン、2回目は自分自身を返し、タッチが盾に
        // 吸収された)。ヒットテストで SwiftUI を経由しないよう、UIKit 対象の
        // ボタンも rootView 直下・盾より前面に置く。
        let window = makeWindow()
        let label = UILabel(frame: CGRect(x: 16, y: 100, width: 100, height: 20))
        window.addSubview(label)
        let overlay = MonitorOverlay()
        overlay.show(on: window)

        let shieldIndex = try #require(window.subviews.firstIndex { $0 is MonitorShieldView })
        let buttonIndex = try #require(window.subviews.firstIndex { $0 is MonitorButton })
        #expect(buttonIndex > shieldIndex)

        let hit = try #require(window.hitTest(CGPoint(x: 50, y: 110), with: nil))
        let hitsMonitorButton = sequence(first: hit, next: { $0.superview })
            .contains { $0 is MonitorButton }
        #expect(hitsMonitorButton)
        overlay.hide()
    }

    @Test("隠れているビューには計測ボタンを付けない")
    func skipsInvisibleTargets() throws {
        // ボタンは rootView 直下の固定配置になったため、隠れた親の内側に
        // 居た頃と違い、対象が不可視でもボタンだけが画面に浮いてしまう
        // (大タイトル表示中の インラインナビタイトル UILabel で実際に発生)。
        // 不可視の対象はボタン自体を付けない。
        let window = makeWindow()
        let hiddenContainer = UIView(frame: CGRect(x: 0, y: 200, width: 200, height: 40))
        hiddenContainer.isHidden = true
        let labelInHidden = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 20))
        hiddenContainer.addSubview(labelInHidden)
        let transparentLabel = UILabel(frame: CGRect(x: 0, y: 300, width: 100, height: 20))
        transparentLabel.alpha = 0
        let visibleLabel = UILabel(frame: CGRect(x: 0, y: 400, width: 100, height: 20))
        window.addSubview(hiddenContainer)
        window.addSubview(transparentLabel)
        window.addSubview(visibleLabel)
        let overlay = MonitorOverlay()

        overlay.show(on: window)

        let buttons = window.subviews.compactMap { $0 as? MonitorButton }
        #expect(buttons.count == 1)
        if case .uiKitView(let target) = buttons.first?.measurementTarget {
            #expect(target === visibleLabel)
        }
        overlay.hide()
    }

    @Test("SwiftUI 要素の計測ボタンと InfoView は盾より前面に居る")
    func overlayUIStaysAboveShield() throws {
        let window = makeWindow()
        let host = UIView()
        let element = UIAccessibilityElement(accessibilityContainer: host)
        element.isAccessibilityElement = true
        element.accessibilityTraits = .staticText
        element.accessibilityFrame = CGRect(x: 40, y: 200, width: 100, height: 30)
        host.accessibilityElements = [element]
        window.addSubview(host)
        let overlay = MonitorOverlay(scanner: ViewHierarchyScanner(isHostingView: { $0 === host }))
        overlay.show(on: window)

        let shieldIndex = try #require(window.subviews.firstIndex { $0 is MonitorShieldView })
        let buttonIndex = try #require(window.subviews.firstIndex { $0 is MonitorButton })
        let infoIndex = try #require(window.subviews.firstIndex { $0 is InfoView })
        #expect(buttonIndex > shieldIndex)
        #expect(infoIndex > shieldIndex)
        overlay.hide()
    }
}
