//
//  UIColor+Hex.swift
//  ViewMonitor
//

import UIKit

extension UIColor {

    /// `#RRGGBB` または `RRGGBB` 形式の文字列から生成する。
    /// 解釈できない場合は nil を返す。
    convenience init?(monitorHex hex: String, alpha: CGFloat = 1.0) {
        var string = hex
        if string.hasPrefix("#") {
            string.removeFirst()
        }
        guard string.count == 6, let value = UInt32(string, radix: 16) else {
            return nil
        }
        self.init(
            red: CGFloat((value & 0xFF_00_00) >> 16) / 255.0,
            green: CGFloat((value & 0x00_FF_00) >> 8) / 255.0,
            blue: CGFloat(value & 0x00_00_FF) / 255.0,
            alpha: alpha
        )
    }

    /// `RRGGBB` 形式の小文字16進文字列を返す。取得できない場合は nil。
    ///
    /// `getRed(_:green:blue:alpha:)` は変換可能な色空間を自動で RGB に
    /// 変換するため、グレースケール色空間の `UIColor.black` /
    /// `UIColor.white` も正しく扱える。
    var monitorHexString: String? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }
        let channel: (CGFloat) -> Int = { Int((max(0, min(1, $0)) * 255).rounded()) }
        return String(format: "%02x%02x%02x", channel(red), channel(green), channel(blue))
    }
}
