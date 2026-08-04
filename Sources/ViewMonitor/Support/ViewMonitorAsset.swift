//
//  ViewMonitorAsset.swift
//  ViewMonitor
//

import UIKit

/// バンドル同梱の画像リソース。
enum ViewMonitorAsset {

    static var button: UIImage? { image(named: "button") }

    static var buttonSelected: UIImage? { image(named: "button_selected") }

    private static func image(named name: String) -> UIImage? {
        if let image = UIImage(named: name, in: .viewMonitor, compatibleWith: nil) {
            return image
        }
        // アセットカタログ外の PNG はバンドル直下に配置されるため、
        // ファイルURL経由でも取得を試みる。
        guard let url = Bundle.viewMonitor.url(forResource: name, withExtension: "png") else {
            return nil
        }
        return UIImage(contentsOfFile: url.path)
    }
}
