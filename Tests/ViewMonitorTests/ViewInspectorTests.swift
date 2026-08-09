import Testing
import UIKit
@testable import ViewMonitor

@Suite("ViewInspector")
@MainActor
struct ViewInspectorTests {

    @Test("ビューのサイズを取り出す")
    func readsSize() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 120, height: 40))

        let inspection = ViewInspector.inspect(view, in: nil)

        #expect(inspection.size == CGSize(width: 120, height: 40))
    }

    @Test("背景色を16進文字列で取り出す")
    func readsBackgroundColor() {
        let view = UIView()
        view.backgroundColor = UIColor(monitorHex: "7ED321")

        let inspection = ViewInspector.inspect(view, in: nil)

        #expect(inspection.backgroundColorHex == "7ed321")
    }

    @Test("背景色が未設定なら nil を返す")
    func returnsNilForMissingBackgroundColor() {
        let inspection = ViewInspector.inspect(UIView(), in: nil)

        #expect(inspection.backgroundColorHex == nil)
    }

    @Test("グレースケール色空間の背景色も取り出せる")
    func readsMonochromeBackgroundColor() {
        let view = UIView()
        view.backgroundColor = .black

        let inspection = ViewInspector.inspect(view, in: nil)

        #expect(inspection.backgroundColorHex == "000000")
    }

    @Test("UILabel からフォント情報を取り出す")
    func readsFontInfoFromLabel() throws {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = UIColor(monitorHex: "FF0000")

        let inspection = ViewInspector.inspect(label, in: nil)
        let font = try #require(inspection.font)

        #expect(font.pointSize == 17)
        #expect(font.familyName == UIFont.systemFont(ofSize: 17).familyName)
        #expect(font.colorHex == "ff0000")
    }

    @Test("UILabel 以外はフォント情報を持たない")
    func returnsNilFontForNonLabel() {
        let inspection = ViewInspector.inspect(UIImageView(), in: nil)

        #expect(inspection.font == nil)
    }

    @Test("親にオフセットがある場合もウィンドウ座標に変換する")
    func convertsFrameToWindowCoordinates() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let container = UIView(frame: CGRect(x: 30, y: 50, width: 200, height: 200))
        let label = UILabel(frame: CGRect(x: 10, y: 20, width: 100, height: 30))
        container.addSubview(label)
        window.addSubview(container)

        let inspection = ViewInspector.inspect(label, in: window)

        #expect(inspection.frameInWindow.origin == CGPoint(x: 40, y: 70))
        #expect(inspection.frameInWindow.size == CGSize(width: 100, height: 30))
    }

    @Test("window が nil なら自身の bounds を返す")
    func fallsBackToBoundsWithoutWindow() {
        let view = UIView(frame: CGRect(x: 5, y: 5, width: 60, height: 20))

        let inspection = ViewInspector.inspect(view, in: nil)

        #expect(inspection.frameInWindow == CGRect(x: 0, y: 0, width: 60, height: 20))
    }

    @Test("クラス名を取り出す")
    func readsClassName() {
        let inspection = ViewInspector.inspect(UILabel(), in: nil)

        #expect(inspection.className == "UILabel")
    }

    @Test("alpha を取り出す")
    func readsAlpha() {
        let view = UIView()
        view.alpha = 0.5

        let inspection = ViewInspector.inspect(view, in: nil)

        #expect(inspection.alpha == 0.5)
    }

    @Test("cornerRadius を取り出す")
    func readsCornerRadius() {
        let view = UIView()
        view.layer.cornerRadius = 8

        let inspection = ViewInspector.inspect(view, in: nil)

        #expect(inspection.cornerRadius == 8)
    }

    @Test("UIButton のタイトルからフォント情報を取り出す")
    func readsFontInfoFromButton() throws {
        let button = UIButton(type: .system)
        button.setTitle("Tap", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        button.setTitleColor(UIColor(monitorHex: "FF0000"), for: .normal)

        let inspection = ViewInspector.inspect(button, in: nil)
        let font = try #require(inspection.font)

        #expect(font.pointSize == 15)
        #expect(font.familyName == UIFont.systemFont(ofSize: 15).familyName)
    }

    @Test("アクセシビリティ要素をウィンドウ座標で計測する")
    func inspectsAccessibilityElement() {
        // accessibilityFrame はスクリーン座標。原点 (10, 20) の window では
        // スクリーン (30, 40) が window 座標 (20, 20) になる。
        let window = UIWindow(frame: CGRect(x: 10, y: 20, width: 320, height: 480))
        let element = UIAccessibilityElement(accessibilityContainer: window)
        element.accessibilityLabel = "Hello"
        element.accessibilityFrame = CGRect(x: 30, y: 40, width: 120, height: 20)

        let inspection = ViewInspector.inspect(element: element, kind: "Text", in: window)

        #expect(inspection.className == "Text")
        #expect(inspection.frameInWindow == CGRect(x: 20, y: 20, width: 120, height: 20))
        #expect(inspection.size == CGSize(width: 120, height: 20))
        #expect(inspection.text == "Hello")
        #expect(inspection.backgroundColorHex == nil)
        #expect(inspection.alpha == nil)
        #expect(inspection.cornerRadius == nil)
        #expect(inspection.font == nil)
    }

    @Test("window が nil なら accessibilityFrame をそのまま使う")
    func fallsBackToAccessibilityFrameWithoutWindow() {
        let element = UIAccessibilityElement(accessibilityContainer: UIView())
        element.accessibilityFrame = CGRect(x: 30, y: 40, width: 120, height: 20)

        let inspection = ViewInspector.inspect(element: element, kind: "Button", in: nil)

        #expect(inspection.frameInWindow == CGRect(x: 30, y: 40, width: 120, height: 20))
    }
}
