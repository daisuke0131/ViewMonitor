import Testing
import UIKit
@testable import ViewMonitor

@Suite("MonitorLauncherButton origin(inBounds:safeAreaInsets:)")
@MainActor
struct MonitorLauncherButtonTests {

    @Test("UI テストから掴める accessibilityIdentifier を持つ")
    func exposesAccessibilityIdentifier() {
        let button = MonitorLauncherButton(origin: .zero)
        #expect(button.accessibilityIdentifier == "ViewMonitor.launcher")
    }

    @Test("safe area インセットがゼロなら右上に配置され y == 20 になる")
    func zeroInsetsPlacesButtonAtTopRight() {
        let bounds = CGRect(x: 0, y: 0, width: 390, height: 844)

        let origin = MonitorLauncherButton.origin(inBounds: bounds, safeAreaInsets: .zero)

        #expect(origin.y == 20)
        // x = bounds.maxX(390) - insets.right(0) - size.width(72) - margin(20) = 298。
        // 修正前の固定値 `width - 100.0` は 390 - 100 = 290 だったので、
        // 承認済みの挙動変更どおりボタンが 8pt 右に寄る（298 - 290 == 8）。
        #expect(origin.x == 298)
    }

    @Test("Dynamic Island 相当の top: 59 では y == 79 になる（issue #34 の退行検出）")
    func dynamicIslandTopInsetPushesButtonBelowIsland() {
        let bounds = CGRect(x: 0, y: 0, width: 390, height: 844)
        let insets = UIEdgeInsets(top: 59, left: 0, bottom: 0, right: 0)

        let origin = MonitorLauncherButton.origin(inBounds: bounds, safeAreaInsets: insets)

        #expect(origin.y == 79)
    }

    @Test("横向きノッチ相当の right: 44 では x がその分だけ左に寄る")
    func landscapeNotchRightInsetShiftsButtonLeft() {
        let bounds = CGRect(x: 0, y: 0, width: 926, height: 428)

        let originWithoutInset = MonitorLauncherButton.origin(inBounds: bounds, safeAreaInsets: .zero)
        let originWithInset = MonitorLauncherButton.origin(
            inBounds: bounds,
            safeAreaInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 44)
        )

        #expect(originWithInset.x == originWithoutInset.x - 44)
    }

    @Test("極端に狭い bounds でもボタンは左にはみ出さない")
    func extremelyNarrowBoundsClampsToLeftMargin() {
        let bounds = CGRect(x: 0, y: 0, width: 50, height: 100)

        let origin = MonitorLauncherButton.origin(inBounds: bounds, safeAreaInsets: .zero)

        // クランプ前の x = bounds.maxX(50) - insets.right(0) - size.width(72) - margin(20) = -42。
        // クランプ後は max(bounds.minX(0) + insets.left(0) + margin(20), -42) == 20 になり、
        // 負値（画面外の左はみ出し）にならない。
        #expect(origin.x == 20)
        #expect(origin.x >= bounds.minX)
    }
}
