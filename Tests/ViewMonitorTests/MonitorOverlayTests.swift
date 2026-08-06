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

    private func monitorButton(on view: UIView) -> MonitorButton? {
        view.subviews.compactMap { $0 as? MonitorButton }.first
    }

    private func infoView(in root: UIView) -> InfoView? {
        root.subviews.compactMap { $0 as? InfoView }.first
    }

    private func rowTexts(in root: UIView) -> [String] {
        infoView(in: root)?.rowLabels.compactMap(\.text) ?? []
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

    @Test("targetView が nil のボタンを選択すると全項目 None になる")
    func nilTargetShowsNoneRows() throws {
        // フェーズAで未検証だった防御的経路の回収。
        let window = makeWindow()
        let overlay = MonitorOverlay()
        let label = UILabel(frame: CGRect(x: 16, y: 100, width: 100, height: 20))
        window.addSubview(label)
        overlay.show(on: window)
        let button = try #require(monitorButton(on: label))
        button.targetView = nil

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
}
