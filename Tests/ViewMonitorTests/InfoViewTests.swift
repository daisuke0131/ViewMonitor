import Testing
import UIKit
@testable import ViewMonitor

@Suite("InfoView")
@MainActor
struct InfoViewTests {

    private func makeInfoView() -> InfoView {
        InfoView(frame: CGRect(origin: .zero, size: .zero))
    }

    private var commonRows: [InfoRow] {
        [
            InfoRow(title: "class", value: "UIView"),
            InfoRow(title: "x", value: "16"),
            InfoRow(title: "y", value: "120"),
            InfoRow(title: "width", value: "343"),
            InfoRow(title: "height", value: "20"),
            InfoRow(title: "background", value: "None"),
            InfoRow(title: "alpha", value: "1"),
            InfoRow(title: "cornerRadius", value: "0")
        ]
    }

    private var fontRows: [InfoRow] {
        [
            InfoRow(title: "font", value: "Helvetica"),
            InfoRow(title: "fontSize", value: "17"),
            InfoRow(title: "fontColor", value: "#333333")
        ]
    }

    @Test("行を順序通りに title: value 形式で描画する")
    func rendersRowsInOrder() {
        let infoView = makeInfoView()

        infoView.update(rows: commonRows)

        #expect(infoView.rowLabels.map(\.text) == [
            "class: UIView",
            "x: 16",
            "y: 120",
            "width: 343",
            "height: 20",
            "background: None",
            "alpha: 1",
            "cornerRadius: 0"
        ])
    }

    @Test("行数が増えると高さが伸び、幅は 200 のまま")
    func growsWithRowCount() {
        let infoView = makeInfoView()

        infoView.update(rows: commonRows)
        let commonHeight = infoView.frame.height
        infoView.update(rows: commonRows + fontRows)

        #expect(infoView.frame.height > commonHeight)
        #expect(infoView.frame.width == 200)
    }

    @Test("行が減る再更新で前の行が残らない")
    func doesNotKeepStaleRows() {
        // 2.0.0 で修正したフォント名残留バグ（didSet のリセット漏れ）の回帰ピン。
        // 全行を作り直す方式なら構造的に起こらないことを固定する。
        let infoView = makeInfoView()
        infoView.update(rows: commonRows + fontRows)

        infoView.update(rows: commonRows)

        #expect(infoView.rowLabels.count == 8)
        #expect(infoView.rowLabels.compactMap(\.text).allSatisfy { !$0.contains("Helvetica") })
    }

    @Test("ドラッグ相当の origin 変更後も update で origin が動かない")
    func keepsOriginAcrossUpdates() {
        let infoView = makeInfoView()
        infoView.frame.origin = CGPoint(x: 40, y: 300)

        infoView.update(rows: commonRows)

        #expect(infoView.frame.origin == CGPoint(x: 40, y: 300))
    }
}
