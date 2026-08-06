//
//  InfoView.swift
//  ViewMonitor
//

import SwiftUI
import UIKit

/// 計測結果の行を表示するだけのビュー。計測ロジックも行の組み立ても持たない。
/// 描画は SwiftUI(InfoRowsView)に委譲し、UIKit 側は取り付けとサイズ管理だけを担う。
final class InfoView: UIView {

    /// 表示幅。高さは行数に応じて `update(rows:)` が決める。
    static let width: CGFloat = 200.0

    private let hostingController = UIHostingController(rootView: InfoRowsView(rows: []))

    /// 現在表示中の行。表示内容の検証用。
    var displayedRows: [InfoRow] { hostingController.rootView.rows }

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 10.0
        hostingController.view.backgroundColor = .clear
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostingController.view.frame = bounds
        addSubview(hostingController.view)
        update(rows: [])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 表示行を差し替え、行数に合わせて高さを更新する。
    ///
    /// 毎回すべての行を作り直すため、一部の項目だけ前の値が残ることが起こらない。
    /// 自身のサイズは frame 管理のまま（superview への制約なし）にして、
    /// MonitorOverlay のドラッグ移動（center の書き換え）と衝突させない。
    func update(rows: [InfoRow]) {
        hostingController.rootView = InfoRowsView(rows: rows)
        let height = hostingController.sizeThatFits(
            in: CGSize(width: Self.width, height: .greatestFiniteMagnitude)
        ).height
        frame.size = CGSize(width: Self.width, height: height)
        hostingController.view.frame = bounds
    }
}
