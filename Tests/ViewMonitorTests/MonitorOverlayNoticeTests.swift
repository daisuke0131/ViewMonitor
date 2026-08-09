import Testing
import UIKit
@testable import ViewMonitor

/// SwiftUI 要素が検出できないときの案内表示。
/// iOS はアクセシビリティクライアントが接続している間しかツリーを構築しない
/// ため、素の状態では SwiftUI 要素の検出結果が空になる。無言で0件のままだと
/// 利用者には不具合と区別がつかない(実際に「トグルが効かない」と報告された)。
@Suite("MonitorOverlay accessibility notice")
@MainActor
struct MonitorOverlayNoticeTests {

    private func makeWindow() -> UIWindow {
        UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
    }

    private func infoView(in root: UIView) -> InfoView? {
        root.subviews.compactMap { $0 as? InfoView }.first
    }

    private func makeOverlay(hostingProbe: UIView) -> MonitorOverlay {
        MonitorOverlay(scanner: ViewHierarchyScanner(isHostingView: { $0 === hostingProbe }))
    }

    @Test("ホスティングビューはあるのに AX 要素が0件なら InfoView に案内が出る")
    func showsNoticeWhenAccessibilityTreeIsEmpty() throws {
        let window = makeWindow()
        let host = UIView()
        window.addSubview(host)
        let overlay = makeOverlay(hostingProbe: host)

        overlay.show(on: window)

        let info = try #require(infoView(in: window))
        #expect(!info.isHidden)
        #expect(info.displayedRows.contains { $0.value.contains("not detected") })
    }

    @Test("AX 要素が検出できていれば案内は出ず InfoView は隠れたまま")
    func noNoticeWhenElementsAreDetected() throws {
        let window = makeWindow()
        let host = UIView()
        let element = UIAccessibilityElement(accessibilityContainer: host)
        element.isAccessibilityElement = true
        element.accessibilityTraits = .staticText
        element.accessibilityFrame = CGRect(x: 10, y: 10, width: 50, height: 20)
        host.accessibilityElements = [element]
        window.addSubview(host)
        let overlay = makeOverlay(hostingProbe: host)

        overlay.show(on: window)

        let info = try #require(infoView(in: window))
        #expect(info.isHidden)
    }

    @Test("ホスティングビューが無い純 UIKit 画面では案内は出ない")
    func noNoticeWithoutHostingView() throws {
        let window = makeWindow()
        window.addSubview(UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 20)))
        let overlay = MonitorOverlay()

        overlay.show(on: window)

        let info = try #require(infoView(in: window))
        #expect(info.isHidden)
    }
}
