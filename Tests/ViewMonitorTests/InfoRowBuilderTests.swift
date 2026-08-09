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
        alpha: CGFloat? = 1.0,
        cornerRadius: CGFloat? = 0.0,
        text: String? = nil,
        font: ViewInspection.FontInfo? = nil
    ) -> ViewInspection {
        ViewInspection(
            className: className,
            frameInWindow: CGRect(x: x, y: y, width: width, height: height),
            size: CGSize(width: width, height: height),
            backgroundColorHex: backgroundColorHex,
            alpha: alpha,
            cornerRadius: cornerRadius,
            text: text,
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
        // 計測対象を取得できなかったときの防御的経路。
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

    @Test("分離した参照を渡すと vs 行と gap 行が末尾に並ぶ")
    func appendsDistanceRowsForSeparatedReference() {
        // 現在: y120 h20 → minY 120 / 参照: y76 h20 → maxY 96 → gapY 24。X は同一投影で nil
        let reference = makeInspection(className: "UILabel", y: 76, height: 20)

        let rows = InfoRowBuilder.rows(from: makeInspection(), comparedTo: reference)

        #expect(Array(rows.suffix(2)) == [
            InfoRow(title: "vs", value: "UILabel"),
            InfoRow(title: "gapY", value: "24")
        ])
    }

    @Test("重なっている参照は overlap 行になる")
    func appendsOverlapRows() {
        // 現在 x16..359 y120..140 / 参照 x200..543 y130..150 → overlapX 159, overlapY 10
        let reference = makeInspection(className: "UIView", x: 200, y: 130)

        let rows = InfoRowBuilder.rows(from: makeInspection(), comparedTo: reference)

        #expect(Array(rows.suffix(3)) == [
            InfoRow(title: "vs", value: "UIView"),
            InfoRow(title: "overlapX", value: "159"),
            InfoRow(title: "overlapY", value: "10")
        ])
    }

    @Test("内包する参照はインセット4行になる")
    func appendsInsetRows() {
        // 現在 x16..359 y120..140 は参照 x0..375 y100..160 に内包
        let reference = makeInspection(className: "UIStackView", x: 0, y: 100, width: 375, height: 60)

        let rows = InfoRowBuilder.rows(from: makeInspection(), comparedTo: reference)

        #expect(Array(rows.suffix(5)) == [
            InfoRow(title: "vs", value: "UIStackView"),
            InfoRow(title: "top", value: "20"),
            InfoRow(title: "left", value: "16"),
            InfoRow(title: "bottom", value: "20"),
            InfoRow(title: "right", value: "16")
        ])
    }

    @Test("inspection が nil なら参照があっても距離セクションを出さない")
    func omitsDistanceSectionForNilInspection() {
        let rows = InfoRowBuilder.rows(from: nil, comparedTo: makeInspection())

        #expect(rows.map(\.title) == ["class", "x", "y", "width", "height", "background", "alpha", "cornerRadius"])
    }

    @Test("フォント行の後に距離セクションが来る")
    func distanceSectionFollowsFontRows() {
        let font = ViewInspection.FontInfo(familyName: "Helvetica", pointSize: 17, colorHex: nil)
        let reference = makeInspection(className: "UILabel", y: 76, height: 20)

        let rows = InfoRowBuilder.rows(from: makeInspection(font: font), comparedTo: reference)

        #expect(rows.count == 13)
        #expect(rows[10].title == "fontColor")
        #expect(rows[11] == InfoRow(title: "vs", value: "UILabel"))
    }

    @Test("alpha と cornerRadius が nil なら None と表示する")
    func showsNoneForMissingAlphaAndCornerRadius() {
        // SwiftUI のアクセシビリティ要素では取得できない項目。
        let rows = InfoRowBuilder.rows(from: makeInspection(alpha: nil, cornerRadius: nil))

        #expect(rows[6] == InfoRow(title: "alpha", value: "None"))
        #expect(rows[7] == InfoRow(title: "cornerRadius", value: "None"))
    }

    @Test("text がある計測結果は共通8行の直後に text 行が入る")
    func appendsTextRow() {
        let rows = InfoRowBuilder.rows(from: makeInspection(text: "Hello"))

        #expect(rows.count == 9)
        #expect(rows[8] == InfoRow(title: "text", value: "Hello"))
    }
}
