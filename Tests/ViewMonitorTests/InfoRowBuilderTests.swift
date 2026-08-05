import Testing
import UIKit
@testable import ViewMonitor

@Suite("InfoRowBuilder")
struct InfoRowBuilderTests {

    private func makeInspection(
        className: String = "UIView",
        x: CGFloat = 16,
        y: CGFloat = 120,
        width: CGFloat = 343,
        height: CGFloat = 20,
        backgroundColorHex: String? = nil,
        alpha: CGFloat = 1.0,
        cornerRadius: CGFloat = 0.0,
        font: ViewInspection.FontInfo? = nil
    ) -> ViewInspection {
        ViewInspection(
            className: className,
            frameInWindow: CGRect(x: x, y: y, width: width, height: height),
            size: CGSize(width: width, height: height),
            backgroundColorHex: backgroundColorHex,
            alpha: alpha,
            cornerRadius: cornerRadius,
            font: font
        )
    }

    @Test("フォントなしの計測結果は共通8行を順序通りに返す")
    func returnsCommonRowsForPlainView() {
        let rows = InfoRowBuilder.rows(from: makeInspection(backgroundColorHex: "7ed321"))

        #expect(rows == [
            InfoRow(title: "class", value: "UIView"),
            InfoRow(title: "x", value: "16"),
            InfoRow(title: "y", value: "120"),
            InfoRow(title: "width", value: "343"),
            InfoRow(title: "height", value: "20"),
            InfoRow(title: "background", value: "#7ed321"),
            InfoRow(title: "alpha", value: "1"),
            InfoRow(title: "cornerRadius", value: "0")
        ])
    }

    @Test("フォント付きの計測結果は末尾にフォント3行が並ぶ")
    func appendsFontRows() {
        let font = ViewInspection.FontInfo(familyName: "Helvetica", pointSize: 17, colorHex: "333333")

        let rows = InfoRowBuilder.rows(from: makeInspection(font: font))

        #expect(rows.count == 11)
        #expect(Array(rows.suffix(3)) == [
            InfoRow(title: "font", value: "Helvetica"),
            InfoRow(title: "fontSize", value: "17"),
            InfoRow(title: "fontColor", value: "#333333")
        ])
    }

    @Test("nil は共通8行を全て None で返す")
    func returnsNoneRowsForNil() {
        // 選択ボタンの targetView（弱参照）が解放済みのときに通る経路。
        // 前のビューの計測値を出し続けない。
        let rows = InfoRowBuilder.rows(from: nil)

        #expect(rows.map(\.title) == ["class", "x", "y", "width", "height", "background", "alpha", "cornerRadius"])
        #expect(rows.allSatisfy { $0.value == "None" })
    }

    @Test("背景色が nil なら None と表示する")
    func showsNoneForMissingBackground() {
        let rows = InfoRowBuilder.rows(from: makeInspection())

        #expect(rows[5] == InfoRow(title: "background", value: "None"))
    }

    @Test("数値は小数第1位に丸め、整数になる値は .0 を落とす", arguments: [
        (CGFloat(16.0), "16"),
        (CGFloat(20.5), "20.5"),
        (CGFloat(16.6667), "16.7"),
        (CGFloat(0), "0"),
        (CGFloat.infinity, "inf")
    ])
    func formatsNumbers(pair: (CGFloat, String)) {
        let rows = InfoRowBuilder.rows(from: makeInspection(x: pair.0))

        #expect(rows[1] == InfoRow(title: "x", value: pair.1))
    }
}
