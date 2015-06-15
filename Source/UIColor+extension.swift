//
//  UIColor+extension.swift
//  viewMonitor
//

import UIKit

extension UIColor {
    func toHexString() -> String?{
        return self.CGColor.rgbHexString()
    }
    
    class func hexStr (var hexStr : NSString, var alpha : CGFloat) -> UIColor {
        hexStr = hexStr.stringByReplacingOccurrencesOfString("#", withString: "")
        let scanner = NSScanner(string: hexStr as String)
        var color: UInt32 = 0
        if scanner.scanHexInt(&color) {
            let r = CGFloat((color & 0xFF0000) >> 16) / 255.0
            let g = CGFloat((color & 0x00FF00) >> 8) / 255.0
            let b = CGFloat(color & 0x0000FF) / 255.0
            return UIColor(red:r,green:g,blue:b,alpha:alpha)
        } else {
            return UIColor.whiteColor();
        }
    }
    
}

extension CGColor {
    
    func rgbHexString() -> String?{
        if let rgb = self.rgb(){
            let hex = rgb.r * 0x10000 + rgb.g * 0x100 + rgb.b
            return String(format:"%06x", hex)
        }else{
            return nil
        }
    }
    
    func rgb() -> (r:Int,g:Int,b:Int)?{
        let cs = CGColorGetColorSpace(self)
        let csModel = CGColorSpaceGetModel(cs)
        if csModel.value == kCGColorSpaceModelRGB.value {
            let components = CGColorGetComponents(self)
            let r: Int = Int(components[0] * 255.0)
            let g: Int = Int(components[1] * 255.0)
            let b: Int = Int(components[2] * 255.0)
            return (r, g, b)
        } else {
            return nil
        }
    }
}