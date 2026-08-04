//
//  InfoView.swift
//  ViewMonitor
//

import UIKit

class InfoView: UIView {

    let x: UILabel
    let y: UILabel
    let width: UILabel
    let height: UILabel
    let bkColor: UILabel
    let font: UILabel
    let fontSize: UILabel
    let fontColor: UILabel
    let margin: CGFloat = 22.0

    var targetView: AnyObject? {
        didSet {
            if let target = targetView as? UIView {
                x.text = "x:None"
                y.text = "y:None"
                width.text = "width:None"
                height.text = "height:None"
                bkColor.text = "background:None"
                fontSize.text = "fontSize:None"
                fontColor.text = "fontColor:None"

                x.font = UIFont.systemFont(ofSize: 11)
                y.font = UIFont.systemFont(ofSize: 11)
                width.font = UIFont.systemFont(ofSize: 11)
                height.font = UIFont.systemFont(ofSize: 11)
                bkColor.font = UIFont.systemFont(ofSize: 11)
                font.font = UIFont.systemFont(ofSize: 11)
                fontSize.font = UIFont.systemFont(ofSize: 11)
                fontColor.font = UIFont.systemFont(ofSize: 11)

                let window = WindowProvider.keyWindow
                // coordinate　conversion
                let rect = window?.convert(targetView!.bounds, from: target)
                if let rect = rect {
                    x.text = "x:\(rect.origin.x)"
                    y.text = "y:\(rect.origin.y)"
                    width.text = "width:\(target.frame.size.width)"
                    height.text = "height:\(target.frame.size.height)"
                    if let background = target.backgroundColor {
                        if let hex = background.monitorHexString {
                            bkColor.text = "background:#\(hex)"
                        }
                    }
                }

                if let target: AnyObject = targetView {
                    if target is UILabel {
                        // Force cast is safe here: guarded by `target is UILabel` above.
                        // Restructuring this to avoid the cast belongs to the InfoView
                        // display-only refactor (later task), not this formatting pass.
                        // swiftlint:disable:next force_cast
                        fontSize.text = "fontSize:\((target as! UILabel).font.pointSize)"

                        if let label = target as? UILabel {
                            if let color = label.textColor, let f = label.font {
                                if let hex = color.monitorHexString {
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
        x.textColor = UIColor.white
        y = UILabel(frame: CGRect(x: margin, y: 30.0, width: frame.size.width - 20.0, height: 20.0))
        y.text = "y:None"
        y.textColor = UIColor.white
        width = UILabel(frame: CGRect(x: margin, y: 50.0, width: frame.size.width - 20.0, height: 20.0))
        width.text = "width:None"
        width.textColor = UIColor.white
        height = UILabel(frame: CGRect(x: margin, y: 70.0, width: frame.size.width - 20.0, height: 20.0))
        height.text = "height:None"
        height.textColor = UIColor.white
        bkColor = UILabel(frame: CGRect(x: margin, y: 90.0, width: frame.size.width - 20.0, height: 20.0))
        bkColor.text = "background:None"
        bkColor.textColor = UIColor.white
        font = UILabel(frame: CGRect(x: margin, y: 110.0, width: frame.size.width - 20.0, height: 20.0))
        font.text = "font:None"
        font.textColor = UIColor.white
        fontSize = UILabel(frame: CGRect(x: margin, y: 130.0, width: frame.size.width - 20.0, height: 20.0))
        fontSize.text = "fontSize:None"
        fontSize.textColor = UIColor.white
        fontColor = UILabel(frame: CGRect(x: margin, y: 150.0, width: frame.size.width - 20.0, height: 20.0))
        fontColor.text = "fontColor:None"
        fontColor.textColor = UIColor.white
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

}
