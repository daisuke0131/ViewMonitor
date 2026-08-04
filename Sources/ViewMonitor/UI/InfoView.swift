//
//  InfoView.swift
//  ViewMonitor
//

import UIKit

/// 計測結果を表示するだけのビュー。計測ロジックは持たない。
final class InfoView: UIView {

    let xLabel: UILabel
    let yLabel: UILabel
    let widthLabel: UILabel
    let heightLabel: UILabel
    let backgroundLabel: UILabel
    let fontLabel: UILabel
    let fontSizeLabel: UILabel
    let fontColorLabel: UILabel

    private static let horizontalMargin: CGFloat = 22.0
    private static let rowHeight: CGFloat = 20.0
    private static let firstRowTop: CGFloat = 10.0

    override init(frame: CGRect) {
        let width = frame.size.width - 20.0
        func makeLabel(row: Int) -> UILabel {
            let label = UILabel(
                frame: CGRect(
                    x: InfoView.horizontalMargin,
                    y: InfoView.firstRowTop + CGFloat(row) * InfoView.rowHeight,
                    width: width,
                    height: InfoView.rowHeight
                )
            )
            label.textColor = .white
            label.font = .systemFont(ofSize: 11)
            return label
        }

        xLabel = makeLabel(row: 0)
        yLabel = makeLabel(row: 1)
        widthLabel = makeLabel(row: 2)
        heightLabel = makeLabel(row: 3)
        backgroundLabel = makeLabel(row: 4)
        fontLabel = makeLabel(row: 5)
        fontSizeLabel = makeLabel(row: 6)
        fontColorLabel = makeLabel(row: 7)

        super.init(frame: frame)

        for label in allLabels {
            addSubview(label)
        }
        layer.cornerRadius = 10.0
        update(with: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var allLabels: [UILabel] {
        [xLabel, yLabel, widthLabel, heightLabel, backgroundLabel, fontLabel, fontSizeLabel, fontColorLabel]
    }

    /// 計測結果を表示する。`nil` を渡すと全ての項目が `None` になる。
    ///
    /// 8つのラベルを毎回まとめて更新するため、
    /// 一部の項目だけ前の値が残ることが起こらない。
    func update(with inspection: ViewInspection?) {
        xLabel.text = "x:" + text(inspection.map { "\($0.frameInWindow.origin.x)" })
        yLabel.text = "y:" + text(inspection.map { "\($0.frameInWindow.origin.y)" })
        widthLabel.text = "width:" + text(inspection.map { "\($0.size.width)" })
        heightLabel.text = "height:" + text(inspection.map { "\($0.size.height)" })
        backgroundLabel.text = "background:" + text(inspection?.backgroundColorHex.map { "#\($0)" })
        fontLabel.text = "font:" + text(inspection?.font?.familyName)
        fontSizeLabel.text = "fontSize:" + text(inspection?.font.map { "\($0.pointSize)" })
        fontColorLabel.text = "fontColor:" + text(inspection?.font?.colorHex.map { "#\($0)" })
    }

    private func text(_ value: String?) -> String {
        value ?? "None"
    }
}
