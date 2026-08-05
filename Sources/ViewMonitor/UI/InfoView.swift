//
//  InfoView.swift
//  ViewMonitor
//

import UIKit

/// 計測結果の行を表示するだけのビュー。計測ロジックも行の組み立ても持たない。
final class InfoView: UIView {

    /// 表示幅。高さは行数に応じて `update(rows:)` が決める。
    static let width: CGFloat = 200.0

    private static let contentInsets = UIEdgeInsets(top: 10.0, left: 22.0, bottom: 10.0, right: 10.0)

    private let stackView = UIStackView()

    /// 現在表示中の行ラベル。表示内容の検証用。
    var rowLabels: [UILabel] {
        stackView.arrangedSubviews.compactMap { $0 as? UILabel }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 10.0
        stackView.axis = .vertical
        stackView.spacing = 6.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: Self.contentInsets.top),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.contentInsets.left),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.contentInsets.right),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Self.contentInsets.bottom)
        ])
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
        for view in stackView.arrangedSubviews {
            view.removeFromSuperview()
        }
        for row in rows {
            let label = UILabel()
            label.textColor = .white
            label.font = .systemFont(ofSize: 11)
            label.text = "\(row.title): \(row.value)"
            stackView.addArrangedSubview(label)
        }
        let height = systemLayoutSizeFitting(
            CGSize(width: Self.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        frame.size = CGSize(width: Self.width, height: height)
    }
}
