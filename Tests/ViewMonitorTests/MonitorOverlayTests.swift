import Testing
import UIKit
@testable import ViewMonitor

@Suite("MonitorOverlay")
@MainActor
struct MonitorOverlayTests {

    private func makeWindow() -> UIWindow {
        // 素の UIView をルートにすると frameInWindow が bounds にフォールバックして
        // 全ビューが原点で重なるため、実座標が出る UIWindow をルートにする。
        UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
    }

    /// 計測ボタンは対象の種類によらず rootView(=window)直下に付く。
    /// `view` が対象の UIKit ビューならそのボタンを、`view` が window なら
    /// SwiftUI 要素(アクセシビリティ要素)のボタンを返す。
    private func monitorButton(on view: UIView) -> MonitorButton? {
        let root = (view as? UIWindow) ?? view.window
        return root?.subviews.compactMap { $0 as? MonitorButton }.first { button in
            switch button.measurementTarget {
            case .uiKitView(let target):
                return target === view
            case .accessibilityElement:
                return view is UIWindow
            case nil:
                return false
            }
        }
    }

    private func infoView(in root: UIView) -> InfoView? {
        root.subviews.compactMap { $0 as? InfoView }.first
    }

    private func rowTexts(in root: UIView) -> [String] {
        infoView(in: root)?.displayedRows.map { "\($0.title): \($0.value)" } ?? []
    }

    /// 疑似ホスティングビューと、その上のアクセシビリティ要素を1つ作る。
    private func makeAccessibilityProbe(
        frame: CGRect,
        label: String? = nil,
        traits: UIAccessibilityTraits = .staticText
    ) -> (host: UIView, element: UIAccessibilityElement) {
        let host = UIView()
        let element = UIAccessibilityElement(accessibilityContainer: host)
        element.isAccessibilityElement = true
        element.accessibilityTraits = traits
        element.accessibilityLabel = label
        element.accessibilityFrame = frame
        host.accessibilityElements = [element]
        return (host, element)
    }

    private func makeOverlay(hostingProbe: UIView) -> MonitorOverlay {
        MonitorOverlay(scanner: ViewHierarchyScanner(isHostingView: { $0 === hostingProbe }))
    }

    @Test("1つ目の選択では距離セクションが出ない")
    func firstSelectionHasNoDistanceSection() throws {
        let window = makeWindow()
        let overlay = MonitorOverlay()
        let label = UILabel(frame: CGRect(x: 16, y: 100, width: 100, height: 20))
        window.addSubview(label)
        overlay.show(on: window)

        overlay.select(sender: try #require(monitorButton(on: label)))

        #expect(!rowTexts(in: window).contains { $0.hasPrefix("vs:") })
    }

    @Test("2つ目の選択で vs 行と距離行が出る")
    func secondSelectionShowsDistanceSection() throws {
        let window = makeWindow()
        let overlay = MonitorOverlay()
        let label = UILabel(frame: CGRect(x: 16, y: 100, width: 100, height: 20))
        let image = UIImageView(frame: CGRect(x: 16, y: 144, width: 100, height: 40))
        window.addSubview(label)
        window.addSubview(image)
        overlay.show(on: window)

        overlay.select(sender: try #require(monitorButton(on: label)))
        overlay.select(sender: try #require(monitorButton(on: image)))

        let texts = rowTexts(in: window)
        #expect(texts.contains("vs: UILabel"))
        #expect(texts.contains("gapY: 24"))
        #expect(!texts.contains { $0.hasPrefix("gapX:") })
    }

    @Test("同じボタンの再選択では距離セクションが出ない")
    func reselectingSameButtonHasNoDistanceSection() throws {
        // ON → OFF → ON で参照が自分自身にならないこと。
        let window = makeWindow()
        let overlay = MonitorOverlay()
        let label = UILabel(frame: CGRect(x: 16, y: 100, width: 100, height: 20))
        window.addSubview(label)
        overlay.show(on: window)
        let button = try #require(monitorButton(on: label))

        overlay.select(sender: button)
        overlay.select(sender: button)
        overlay.select(sender: button)

        #expect(!rowTexts(in: window).contains { $0.hasPrefix("vs:") })
    }

    @Test("参照ビューが window から外れていたら距離セクションを出さない")
    func removedReferenceOmitsDistanceSection() throws {
        let window = makeWindow()
        let overlay = MonitorOverlay()
        let label = UILabel(frame: CGRect(x: 16, y: 100, width: 100, height: 20))
        let image = UIImageView(frame: CGRect(x: 16, y: 144, width: 100, height: 40))
        window.addSubview(label)
        window.addSubview(image)
        overlay.show(on: window)
        let labelButton = try #require(monitorButton(on: label))
        let imageButton = try #require(monitorButton(on: image))

        overlay.select(sender: labelButton)
        label.removeFromSuperview()
        overlay.select(sender: imageButton)

        #expect(!rowTexts(in: window).contains { $0.hasPrefix("vs:") })
    }

    @Test("measurementTarget が nil のボタンを選択すると全項目 None になる")
    func nilMeasurementTargetShowsNoneRows() throws {
        // フェーズAで未検証だった防御的経路の回収。
        let window = makeWindow()
        let overlay = MonitorOverlay()
        let label = UILabel(frame: CGRect(x: 16, y: 100, width: 100, height: 20))
        window.addSubview(label)
        overlay.show(on: window)
        let button = try #require(monitorButton(on: label))
        button.measurementTarget = nil

        overlay.select(sender: button)

        let texts = rowTexts(in: window)
        #expect(texts.count == 8)
        #expect(texts.allSatisfy { $0.hasSuffix(": None") })
    }

    @Test("2つ目の選択で参照ビューに青枠が残る")
    func secondSelectionMarksReferenceWithBlueBorder() throws {
        let window = makeWindow()
        let overlay = MonitorOverlay()
        let label = UILabel(frame: CGRect(x: 16, y: 100, width: 100, height: 20))
        let image = UIImageView(frame: CGRect(x: 16, y: 144, width: 100, height: 40))
        window.addSubview(label)
        window.addSubview(image)
        overlay.show(on: window)
        let labelButton = try #require(monitorButton(on: label))
        let imageButton = try #require(monitorButton(on: image))

        overlay.select(sender: labelButton)
        overlay.select(sender: imageButton)

        #expect(imageButton.layer.borderWidth == 2.0)
        #expect(imageButton.layer.borderColor == UIColor.red.cgColor)
        #expect(labelButton.layer.borderWidth == 2.0)
        #expect(labelButton.layer.borderColor == UIColor.systemBlue.cgColor)
        #expect(labelButton.isSelected == false)
    }

    @Test("3つ目の選択で青枠は直前の選択に移る")
    func thirdSelectionMovesBlueBorder() throws {
        let window = makeWindow()
        let overlay = MonitorOverlay()
        let first = UILabel(frame: CGRect(x: 16, y: 100, width: 100, height: 20))
        let second = UIImageView(frame: CGRect(x: 16, y: 144, width: 100, height: 40))
        let third = UILabel(frame: CGRect(x: 16, y: 208, width: 100, height: 20))
        window.addSubview(first)
        window.addSubview(second)
        window.addSubview(third)
        overlay.show(on: window)
        let firstButton = try #require(monitorButton(on: first))
        let secondButton = try #require(monitorButton(on: second))
        let thirdButton = try #require(monitorButton(on: third))

        overlay.select(sender: firstButton)
        overlay.select(sender: secondButton)
        overlay.select(sender: thirdButton)

        #expect(thirdButton.layer.borderColor == UIColor.red.cgColor)
        #expect(secondButton.layer.borderColor == UIColor.systemBlue.cgColor)
        #expect(firstButton.layer.borderWidth == 0.0)
    }

    @Test("参照が無効なら青枠を出さない")
    func invalidReferenceGetsNoBlueBorder() throws {
        let window = makeWindow()
        let overlay = MonitorOverlay()
        let label = UILabel(frame: CGRect(x: 16, y: 100, width: 100, height: 20))
        let image = UIImageView(frame: CGRect(x: 16, y: 144, width: 100, height: 40))
        window.addSubview(label)
        window.addSubview(image)
        overlay.show(on: window)
        let labelButton = try #require(monitorButton(on: label))
        let imageButton = try #require(monitorButton(on: image))

        overlay.select(sender: labelButton)
        label.removeFromSuperview()
        overlay.select(sender: imageButton)

        #expect(labelButton.layer.borderWidth == 0.0)
    }

    @Test("SwiftUI 要素のボタンは rootView 直下に要素の frame で付く")
    func attachesAccessibilityButtonToRootView() throws {
        // makeWindow() は原点 (0, 0) のためスクリーン座標 = window 座標。
        let window = makeWindow()
        let (host, _) = makeAccessibilityProbe(frame: CGRect(x: 16, y: 100, width: 120, height: 20))
        window.addSubview(host)
        let overlay = makeOverlay(hostingProbe: host)

        overlay.show(on: window)

        let button = try #require(monitorButton(on: window))
        #expect(button.frame == CGRect(x: 16, y: 100, width: 120, height: 20))
    }

    @Test("SwiftUI 要素の選択で種別・テキスト行が出て、取れない項目は None になる")
    func selectingAccessibilityTargetShowsKindAndText() throws {
        let window = makeWindow()
        let (host, _) = makeAccessibilityProbe(
            frame: CGRect(x: 16, y: 100, width: 120, height: 20),
            label: "Hello"
        )
        window.addSubview(host)
        let overlay = makeOverlay(hostingProbe: host)
        overlay.show(on: window)

        overlay.select(sender: try #require(monitorButton(on: window)))

        let texts = rowTexts(in: window)
        #expect(texts.contains("class: Text"))
        #expect(texts.contains("text: Hello"))
        #expect(texts.contains("alpha: None"))
        #expect(texts.contains("cornerRadius: None"))
    }

    @Test("要素が破棄された後の選択は全項目 None になる")
    func deallocatedElementShowsNoneRows() throws {
        let window = makeWindow()
        let host = UIView()
        var element: UIAccessibilityElement? = UIAccessibilityElement(accessibilityContainer: host)
        element?.isAccessibilityElement = true
        element?.accessibilityTraits = .staticText
        element?.accessibilityFrame = CGRect(x: 16, y: 100, width: 120, height: 20)
        host.accessibilityElements = element.map { [$0] }
        window.addSubview(host)
        let overlay = makeOverlay(hostingProbe: host)
        overlay.show(on: window)
        let button = try #require(monitorButton(on: window))

        host.accessibilityElements = nil
        element = nil
        overlay.select(sender: button)

        let texts = rowTexts(in: window)
        #expect(texts.count == 8)
        #expect(texts.allSatisfy { $0.hasSuffix(": None") })
    }

    @Test("UIKit ビューと SwiftUI 要素の距離セクションが出る")
    func distanceSectionAcrossUIKitAndSwiftUI() throws {
        let window = makeWindow()
        let label = UILabel(frame: CGRect(x: 16, y: 100, width: 100, height: 20))
        let (host, _) = makeAccessibilityProbe(frame: CGRect(x: 16, y: 144, width: 120, height: 20))
        window.addSubview(label)
        window.addSubview(host)
        let overlay = makeOverlay(hostingProbe: host)
        overlay.show(on: window)
        let labelButton = try #require(monitorButton(on: label))
        let elementButton = try #require(monitorButton(on: window))

        overlay.select(sender: labelButton)
        overlay.select(sender: elementButton)

        let texts = rowTexts(in: window)
        #expect(texts.contains("vs: UILabel"))
        #expect(texts.contains("gapY: 24"))
    }

    @Test("infoView と重なる SwiftUI 要素のボタンを追加しても infoView が最前面に留まる")
    func infoViewStaysInFrontOfOverlappingAccessibilityButton() throws {
        // infoView は (width - 220, 70) 付近に表示される。SwiftUI 要素のボタンは
        // rootView に直接addSubviewされるため、対策前は後から追加された分だけ
        // infoView より前面に来てドラッグ操作やタップを奪ってしまっていた。
        let window = makeWindow()
        let (host, _) = makeAccessibilityProbe(frame: CGRect(x: 150, y: 80, width: 100, height: 40))
        window.addSubview(host)
        let overlay = makeOverlay(hostingProbe: host)

        overlay.show(on: window)

        let button = try #require(monitorButton(on: window))
        let info = try #require(infoView(in: window))
        let buttonIndex = try #require(window.subviews.firstIndex { $0 === button })
        let infoIndex = try #require(window.subviews.firstIndex { $0 === info })
        #expect(infoIndex > buttonIndex)
    }
}
