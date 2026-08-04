import Testing
import UIKit
@testable import ViewMonitor

@Suite("UIColor+Hex")
struct UIColorHexTests {

    @Test("先頭の # ありでも解釈できる")
    func parsesWithHash() throws {
        let color = try #require(UIColor(monitorHex: "#7ED321"))

        #expect(color.monitorHexString == "7ed321")
    }

    @Test("先頭の # なしでも解釈できる")
    func parsesWithoutHash() throws {
        let color = try #require(UIColor(monitorHex: "7ED321"))

        #expect(color.monitorHexString == "7ed321")
    }

    @Test("小文字でも解釈できる")
    func parsesLowercase() throws {
        let color = try #require(UIColor(monitorHex: "7ed321"))

        #expect(color.monitorHexString == "7ed321")
    }

    @Test("alpha を指定できる")
    func appliesAlpha() throws {
        let color = try #require(UIColor(monitorHex: "7ED321", alpha: 0.5))
        var alpha: CGFloat = 0
        color.getRed(nil, green: nil, blue: nil, alpha: &alpha)

        #expect(abs(alpha - 0.5) < 0.001)
    }

    @Test("16進として解釈できない文字列は nil を返す", arguments: ["ZZZZZZ", "#GGGGGG", "      "])
    func rejectsInvalidStrings(input: String) {
        #expect(UIColor(monitorHex: input) == nil)
    }

    @Test("6桁でない文字列は nil を返す", arguments: ["", "FFF", "7ED3213", "#"])
    func rejectsWrongLength(input: String) {
        #expect(UIColor(monitorHex: input) == nil)
    }

    @Test("グレースケール色空間の黒を変換できる")
    func convertsMonochromeBlack() {
        // UIColor.black はグレースケール色空間のため、
        // CGColorSpace のモデルを直接見る実装では nil を返していた。
        #expect(UIColor.black.monitorHexString == "000000")
    }

    @Test("グレースケール色空間の白を変換できる")
    func convertsMonochromeWhite() {
        #expect(UIColor.white.monitorHexString == "ffffff")
    }

    @Test("RGB 色空間の色を変換できる")
    func convertsRGBColor() {
        #expect(UIColor.red.monitorHexString == "ff0000")
    }

    @Test("アルファ付きの色でも RGB 成分だけを返す")
    func ignoresAlphaWhenEncoding() throws {
        let color = try #require(UIColor(monitorHex: "7ED321", alpha: 0.3))

        #expect(color.monitorHexString == "7ed321")
    }
}
