import Testing
import UIKit
@testable import ViewMonitor

@Suite("MonitorConfiguration")
struct MonitorConfigurationTests {

    @Test("オーバーレイ自身のクラスを除外対象に含む")
    func rejectsOverlayClasses() {
        let configuration = MonitorConfiguration.default

        #expect(configuration.rejectedClassNames.contains("MonitorButton"))
        #expect(configuration.rejectedClassNames.contains("MonitorLauncherButton"))
        #expect(configuration.rejectedClassNames.contains("InfoView"))
    }

    @Test("システムのバーとレイアウトガイドを除外対象に含む")
    func rejectsSystemClasses() {
        let configuration = MonitorConfiguration.default

        #expect(configuration.rejectedClassNames.contains("UITabBar"))
        #expect(configuration.rejectedClassNames.contains("UINavigationBar"))
        #expect(configuration.rejectedClassNames.contains("_UILayoutGuide"))
    }

    @Test("既定では追加の対象クラスを持たない")
    func hasNoAdditionalTargetsByDefault() {
        #expect(MonitorConfiguration.default.additionalTargetClassNames.isEmpty)
    }

    @Test("除外タグは既存の値を保つ")
    func keepsRejectedTag() {
        // 既存ユーザーがこのタグでビューを除外している可能性があるため変更しない。
        #expect(MonitorConfiguration.default.rejectedTag == 5_292_739)
    }

    @Test("オーバーレイの色を解釈できる")
    func overlayColorIsParsable() {
        let configuration = MonitorConfiguration.default

        #expect(UIColor(monitorHex: configuration.overlayColorHex) != nil)
    }
}
