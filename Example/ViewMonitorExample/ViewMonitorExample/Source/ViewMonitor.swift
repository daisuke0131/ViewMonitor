//
//  ViewMonitor.swift
//  ViewMonitor
//

import UIKit
import Foundation

final public class ViewMonitor{
    
    static var sharedInstance = ViewMonitor()
    
    /** target rootView */
    private var rootView:UIView?
    
    //show target view detail
    private var infoView:InfoView?
    
    private var executeButton:MonitorButton?
    
    /** retain my objects */
    private var buttons:[UIButton] = [UIButton]()
    
    private var started:Bool = false
    
    /** do not get these views */
    private let rejectClassNames:[String] = ["MonitorButton","UITabBar","UINavigationBar","InfoView"]
    private let kRejectTag = 5292739
    
    /** monitor these views */
    private let targetClassNames:[String] = ["UIButton","UILabel","UIImageView"]
    
    public class func start(){
        if !sharedInstance.started{
            sharedInstance.fookViewEvent()
            sharedInstance.started = true
            
        }
    }
    
    public class func stop(){
        if sharedInstance.started{
            sharedInstance.terminate()
            sharedInstance.started = false
        }
    }
    
    private func execute(){
        makeMonitorView()
        analyzeAllViews()
    }
    
    private func terminate(){
        deleteAllMonitorViews()
        deleteInfoView()
    }

    private func makeMonitorView(){
        addInfoView()
    }
    
    private func deleteExecuteButton(){
        if let executeButton = executeButton{
            executeButton.removeFromSuperview()
            self.executeButton = nil
        }
    }
    
    private func deleteInfoView(){
        if let infoView = infoView{
            infoView.removeFromSuperview()
        }
    }
    
    // swizzling viewDidAppear and viewWillDisappear
    private func fookViewEvent(){
        UIViewController.monitor_methodSwizzling_didAppearWillDisappear()
    }
    
    //viewDidAppear event handling
    public class func detectedViewDidAppear(vc:AnyObject){
        if sharedInstance.started{
            sharedInstance.deleteInfoView()
            sharedInstance.deleteExecuteButton()
            sharedInstance.deleteAllMonitorViews()
            
            let window = UIApplication.sharedApplication().keyWindow
            sharedInstance.rootView = window?.rootViewController?.view

            sharedInstance.addExecuteButton()
        }
    }
    
    private func addExecuteButton(){
        if executeButton == nil{
            let deviceSize:CGSize = UIScreen.mainScreen().bounds.size
            executeButton = MonitorButton(frame: CGRectMake(deviceSize.width - 100.0, 20.0, 72.0, 49.0))
            if let buttonImage = UIImage(named: "button"){
                executeButton?.setBackgroundImage(buttonImage, forState: UIControlState.Normal)
            }else{
                executeButton?.setBackgroundImage(createImageFromUIColor(UIColor.blackColor()), forState: UIControlState.Normal)
            }
            if let buttonSelectedImage = UIImage(named: "button_selected"){
                executeButton?.setBackgroundImage(buttonSelectedImage, forState: UIControlState.Selected)
            }else{
                executeButton?.setBackgroundImage(createImageFromUIColor(UIColor.redColor()), forState: UIControlState.Selected)
            }
            executeButton?.addTarget(self, action: "manualExecute:", forControlEvents: UIControlEvents.TouchUpInside)

            rootView?.addSubview(executeButton!)
            rootView?.bringSubviewToFront(executeButton!)
        }
    
    }
    //execute
    @objc func manualExecute(sender:MonitorButton){
        sender.selected = !sender.selected
        if sender.selected{
            execute()
        }else{
            terminate()
        }
    }
    
    //make 100 * 100 information view
    // have to set tag to reject.
    private func addInfoView(){
        let deviceSize:CGSize = UIScreen.mainScreen().bounds.size
        infoView = InfoView(frame: CGRect(x: deviceSize.width - 220.0, y: 70.0, width: 200.0, height: 150.0))
        let color = UIColor.blackColor()
        let alphaColor = color.colorWithAlphaComponent(0.6)
        infoView?.backgroundColor = alphaColor
        infoView?.hidden = true
        rootView?.addSubview(infoView!)
        rootView?.bringSubviewToFront(infoView!)
    }
    
    private func deleteAllMonitorViews(){
        for button in buttons{
            button.removeFromSuperview()
        }
        buttons.removeAll(keepCapacity: false)
    }

    private func analyzeAllViews(){
        analyzeView(rootView!)
    }
    
    private func analyzeView(view:UIView){
        let window = UIApplication.sharedApplication().keyWindow
        if !checkRejectView(view){
            drawViewOn(view)
        }else{
            return
        }
        //to get child views
        let childViews = view.subviews
        if childViews.count == 0{
            return
        }
        for (var i = 0 ; i < childViews.count ; i++){
            analyzeView(childViews[i] as! UIView)
        }
    }
    private func drawViewOn(view:UIView){
        if checkTargetView(view){
            let button = MonitorButton(frame: CGRectMake(0.0, 0.0, view.frame.size.width, view.frame.size.height))
            button.setBackgroundImage(createImageFromUIColor(hexStr("#7ED321", alpha: 0.7)), forState: UIControlState.Normal)
            button.titleLabel?.font = UIFont.systemFontOfSize(15.0)
            button.addTarget(self, action: "openEditor:", forControlEvents: UIControlEvents.TouchUpInside)
            button.targetView = view
            button.alpha = 0.2
            buttons.append(button)
            if !view.userInteractionEnabled{
                view.userInteractionEnabled = true
            }
            view.addSubview(button)
        }
        
    }
    
    //true: targetList include view
    private func checkTargetView(view:UIView) -> Bool{
        for className in targetClassNames {
            if let viewClass = NSStringFromClass(view.classForCoder).componentsSeparatedByString(".").last where viewClass == className {
                return true
            }
        }
        return false
    }
    
    // true: notTargetList include view
    private func checkRejectView(view:UIView) -> Bool{
        for className in rejectClassNames {
            if let viewClass = NSStringFromClass(view.classForCoder).componentsSeparatedByString(".").last where viewClass == className {
                return true
            }
        }
        if view.tag == kRejectTag{
            return true
        }
        return false
    }
    
    //editor to monitor view
    @objc func openEditor(sender:MonitorButton){
        sender.selected = !sender.selected
        if let infoView = infoView{
            if sender.selected{
                infoView.hidden = false
                infoView.targetView = sender.targetView
            }else{
                infoView.hidden = true
            }
        }
    }
    
    private func hexStr(var hexStr : NSString, var alpha : CGFloat) -> UIColor {
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
    
    private func createImageFromUIColor(color:UIColor) -> UIImage {
        let rect = CGRectMake(0, 0, 1, 1)
        UIGraphicsBeginImageContext(rect.size)
        let contextRef = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(contextRef, color.CGColor)
        CGContextFillRect(contextRef, rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img
    }
}

extension UIViewController{
    class func monitor_methodSwizzling_didAppearWillDisappear() {
        monitor_methodSwizzling_exchange(fromSelector: "viewDidAppear:", toSelector: "monitor_methodSwizzling_viewDidAppear:")
    }
    
    private class func monitor_methodSwizzling_exchange(#fromSelector: Selector, toSelector: Selector) {
        let fromMethod = class_getInstanceMethod(UIViewController.self, fromSelector)
        let toMethod = class_getInstanceMethod(UIViewController.self, toSelector)
        method_exchangeImplementations(fromMethod, toMethod)
    }
    
    func monitor_methodSwizzling_viewDidAppear(animated: Bool) {
        monitor_methodSwizzling_viewDidAppear(animated)
        ViewMonitor.detectedViewDidAppear(self)
    }
}
