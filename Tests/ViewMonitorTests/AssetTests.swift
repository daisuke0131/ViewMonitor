import Testing
import UIKit
@testable import ViewMonitor

@Suite("リソース読み込み")
@MainActor
struct AssetTests {

    @Test("実行ボタンの通常状態の画像を読み込める")
    func loadsButtonImage() {
        #expect(ViewMonitorAsset.button != nil)
    }

    @Test("実行ボタンの選択状態の画像を読み込める")
    func loadsButtonSelectedImage() {
        #expect(ViewMonitorAsset.buttonSelected != nil)
    }

    @Test("読み込んだ画像がサイズを持っている")
    func loadedImageHasNonZeroSize() throws {
        let image = try #require(ViewMonitorAsset.button)

        #expect(image.size.width > 0)
        #expect(image.size.height > 0)
    }
}
