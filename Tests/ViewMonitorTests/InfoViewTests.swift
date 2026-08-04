import Testing
import UIKit
@testable import ViewMonitor

@Suite("InfoView")
@MainActor
struct InfoViewTests {

    private func makeInfoView() -> InfoView {
        InfoView(frame: CGRect(x: 0, y: 0, width: 200, height: 180))
    }

    @Test("nil を渡すと全ての項目が None になる")
    func showsNoneForNilInspection() {
        let infoView = makeInfoView()

        infoView.update(with: nil)

        #expect(infoView.xLabel.text == "x:None")
        #expect(infoView.yLabel.text == "y:None")
        #expect(infoView.widthLabel.text == "width:None")
        #expect(infoView.heightLabel.text == "height:None")
        #expect(infoView.backgroundLabel.text == "background:None")
        #expect(infoView.fontLabel.text == "font:None")
        #expect(infoView.fontSizeLabel.text == "fontSize:None")
        #expect(infoView.fontColorLabel.text == "fontColor:None")
    }

    @Test("背景色を # 付きで表示する")
    func showsBackgroundColorWithHash() {
        let infoView = makeInfoView()
        let view = UIView()
        view.backgroundColor = UIColor(monitorHex: "7ED321")

        infoView.update(with: ViewInspector.inspect(view, in: nil))

        #expect(infoView.backgroundLabel.text == "background:#7ed321")
    }

    @Test("UILabel のフォント名を表示する")
    func showsFontFamilyName() {
        let infoView = makeInfoView()
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)

        infoView.update(with: ViewInspector.inspect(label, in: nil))

        #expect(infoView.fontLabel.text == "font:\(UIFont.systemFont(ofSize: 17).familyName)")
    }

    @Test("UILabel の次にフォントを持たないビューを表示しても前の値が残らない")
    func doesNotKeepStaleFontValue() {
        // 旧実装では didSet のリセットから font だけ漏れており、
        // 前に選んだラベルのフォント名が残り続けていた。
        let infoView = makeInfoView()
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = .red
        infoView.update(with: ViewInspector.inspect(label, in: nil))

        infoView.update(with: ViewInspector.inspect(UIImageView(), in: nil))

        #expect(infoView.fontLabel.text == "font:None")
        #expect(infoView.fontSizeLabel.text == "fontSize:None")
        #expect(infoView.fontColorLabel.text == "fontColor:None")
    }

    @Test("背景色を持つビューの次に持たないビューを表示しても前の値が残らない")
    func doesNotKeepStaleBackgroundValue() {
        let infoView = makeInfoView()
        let colored = UIView()
        colored.backgroundColor = .red
        infoView.update(with: ViewInspector.inspect(colored, in: nil))

        infoView.update(with: ViewInspector.inspect(UIView(), in: nil))

        #expect(infoView.backgroundLabel.text == "background:None")
    }
}
