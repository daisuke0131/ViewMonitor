//
//  UIImage+SolidColor.swift
//  ViewMonitor
//

import UIKit

extension UIImage {

    /// 単色で塗りつぶした画像を作る。
    /// ボタンの背景として引き伸ばして使うため、既定では 1x1 で足りる。
    static func monitorSolidColor(_ color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        let rect = CGRect(origin: .zero, size: size)
        return UIGraphicsImageRenderer(size: size).image { context in
            color.setFill()
            context.fill(rect)
        }
    }
}
