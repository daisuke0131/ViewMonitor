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
    let fontSize:UILabel
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
                
                x.font = UIFont.systemFontOfSize(11)
                y.font = UIFont.systemFontOfSize(11)
                width.font = UIFont.systemFontOfSize(11)
                height.font = UIFont.systemFontOfSize(11)
                bkColor.font = UIFont.systemFontOfSize(11)
                fontSize.font = UIFont.systemFontOfSize(11)

                let window = UIApplication.sharedApplication().keyWindow
                //coordinate　conversion
                let rect = window?.convertRect(targetView!.bounds, fromView: target)
                if let rect = rect{
                    x.text = "x:\(rect.origin.x)"
                    y.text = "y:\(rect.origin.y)"
                    width.text = "width:\(target.frame.size.width)"
                    height.text = "height:\(target.frame.size.height)"
                    if let background = target.backgroundColor{
                        if let hex = background.toHexString(){
                            bkColor.text = "background:#\(hex)"
                        }
                    }
                }
                
                if let target: AnyObject = targetView{
                    if NSStringFromClass(target.classForCoder) == "UILabel"{
                        fontSize.text = "fontSize:\((target as! UILabel).font.pointSize)"
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
        fontSize = UILabel(frame: CGRect(x: margin, y: 110.0, width: frame.size.width - 20.0, height: 20.0))
        fontSize.text = "fontSize:None"
        fontSize.textColor = UIColor.whiteColor()
        super.init(frame: frame)
        self.addSubview(x)
        self.addSubview(y)
        self.addSubview(width)
        self.addSubview(height)
        self.addSubview(bkColor)
        self.addSubview(fontSize)
        self.layer.cornerRadius = 20.0
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}