//
//  InfoView.swift
//  monitorViews
//

import UIKit

class InfoView: UIView {
    
    let x:UILabel
    let y:UILabel
    let width:UILabel
    let height:UILabel
    let bkColor:UILabel
    let font:UILabel
    let fontSize:UILabel
    let fontColor:UILabel
    let margin:CGFloat = 22.0
    
    var targetView:AnyObject?{
        didSet{
            if let target = targetView as? UIView{
                x.text = "x:None"
                y.text = "y:None"
                width.text = "width:None"
                height.text = "height:None"
                bkColor.text = "background:None"
                fontSize.text = "fontSize:None"
                fontColor.text = "fontColor:None"
                
                x.font = UIFont.systemFontOfSize(11)
                y.font = UIFont.systemFontOfSize(11)
                width.font = UIFont.systemFontOfSize(11)
                height.font = UIFont.systemFontOfSize(11)
                bkColor.font = UIFont.systemFontOfSize(11)
                font.font = UIFont.systemFontOfSize(11)
                fontSize.font = UIFont.systemFontOfSize(11)
                fontColor.font = UIFont.systemFontOfSize(11)

                let window = UIApplication.sharedApplication().keyWindow
                //coordinate　conversion
                let rect = window?.convertRect(targetView!.bounds, fromView: target)
                if let rect = rect{
                    x.text = "x:\(rect.origin.x)"
                    y.text = "y:\(rect.origin.y)"
                    width.text = "width:\(target.frame.size.width)"
                    height.text = "height:\(target.frame.size.height)"
                    if let background = target.backgroundColor{
                        if let hex = toHexString(background){
                            bkColor.text = "background:#\(hex)"
                        }
                    }
                }
                
                if let target: AnyObject = targetView{
                    if target is UILabel{
                        fontSize.text = "fontSize:\((target as! UILabel).font.pointSize)"
                        
                        if let label = target as? UILabel{
                            if let color = label.textColor,f = label.font{
                                if let hex = toHexString(color){
                                    fontColor.text = "fontColor:#\(hex)"
                                }
                                font.text = "font:\(f.familyName)"
                            }
                        }
                    }
                }
                
                
            }
            
            
            
        }
    }
    
    override init(frame: CGRect) {
        x = UILabel(frame: CGRect(x: margin, y: 10.0, width: frame.size.width - 20.0, height: 20.0))
        x.text = "x:None"
        x.textColor = UIColor.whiteColor()
        y = UILabel(frame: CGRect(x: margin, y: 30.0, width: frame.size.width - 20.0, height: 20.0))
        y.text = "y:None"
        y.textColor = UIColor.whiteColor()
        width = UILabel(frame: CGRect(x: margin, y: 50.0, width: frame.size.width - 20.0, height: 20.0))
        width.text = "width:None"
        width.textColor = UIColor.whiteColor()
        height = UILabel(frame: CGRect(x: margin, y: 70.0, width: frame.size.width - 20.0, height: 20.0))
        height.text = "height:None"
        height.textColor = UIColor.whiteColor()
        bkColor = UILabel(frame: CGRect(x: margin, y: 90.0, width: frame.size.width - 20.0, height: 20.0))
        bkColor.text = "background:None"
        bkColor.textColor = UIColor.whiteColor()
        font = UILabel(frame: CGRect(x: margin, y: 110.0, width: frame.size.width - 20.0, height: 20.0))
        font.text = "font:None"
        font.textColor = UIColor.whiteColor()
        fontSize = UILabel(frame: CGRect(x: margin, y: 130.0, width: frame.size.width - 20.0, height: 20.0))
        fontSize.text = "fontSize:None"
        fontSize.textColor = UIColor.whiteColor()
        fontColor = UILabel(frame: CGRect(x: margin, y: 150.0, width: frame.size.width - 20.0, height: 20.0))
        fontColor.text = "fontColor:None"
        fontColor.textColor = UIColor.whiteColor()
        super.init(frame: frame)
        self.addSubview(x)
        self.addSubview(y)
        self.addSubview(width)
        self.addSubview(height)
        self.addSubview(bkColor)
        self.addSubview(font)
        self.addSubview(fontSize)
        self.addSubview(fontColor)
        self.layer.cornerRadius = 10.0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func toHexString(color:UIColor) -> String?{
        return rgbHexString(color.CGColor)
    }
    
    private func rgbHexString(cg:CGColor) -> String?{
        if let rgb = rgb(cg){
            let hex = rgb.r * 0x10000 + rgb.g * 0x100 + rgb.b
            return String(format:"%06x", hex)
        }else{
            return nil
        }
    }
    
    func rgb(cg:CGColor) -> (r:Int,g:Int,b:Int)?{
        let cs = CGColorGetColorSpace(cg)
        let csModel = CGColorSpaceGetModel(cs)
        if csModel.rawValue == CGColorSpaceModel.RGB.rawValue {
            let components = CGColorGetComponents(cg)
            let r: Int = Int(components[0] * 255.0)
            let g: Int = Int(components[1] * 255.0)
            let b: Int = Int(components[2] * 255.0)
            return (r, g, b)
        } else {
            return nil
        }
    }

}
