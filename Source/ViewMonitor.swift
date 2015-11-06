//
//  ViewMonitor.swift
//  ViewMonitor
//

import UIKit
import Foundation

final public class ViewMonitor:NSObject{
    
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
    private let rejectClassNames:[String] = ["MonitorButton","UITabBar","UINavigationBar","InfoView","_UILayoutGuide"]
    private let kRejectTag = 5292739
    
    /* userInteractionEnabled */
    private var enabledViews:[UIView] = [UIView]()
    
    /** monitor these views */
    private let targetClassNames:[String] = [""]
    
    public class func start(){
        if !sharedInstance.started{
            sharedInstance.fookViewEvent()
            sharedInstance.setNotification()
            sharedInstance.started = true
        }
    }
    
    public class func stop(){
        if sharedInstance.started{
            sharedInstance.terminate()
            sharedInstance.removeNotification()
            sharedInstance.started = false
        }
    }
    
    private func execute(){
        addInfoView()
        analyzeAllViews()
    }
    
    private func terminate(){
        deleteAllMonitorViews()
        deleteInfoView()
        resetAllInteractionEnabled()
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
            self.infoView = nil
        }
    }
    
    private func setNotification(){
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("orientationChanged:"), name: UIDeviceOrientationDidChangeNotification, object: nil)
    }
    
    private func removeNotification(){
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIDeviceOrientationDidChangeNotification, object: nil)
    }
    
    @objc private func orientationChanged(notification: NSNotification){
        if started{
            deleteInfoView()
            deleteExecuteButton()
            deleteAllMonitorViews()
            resetAllInteractionEnabled()
            rootView = UIApplication.sharedApplication().keyWindow
            addExecuteButton()
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
            sharedInstance.resetAllInteractionEnabled()
            sharedInstance.rootView = UIApplication.sharedApplication().keyWindow
            sharedInstance.addExecuteButton()
            sharedInstance.addInfoView()
        }
    }
    
    private func addExecuteButton(){
        guard let executeButton = executeButton else{
            let deviceSize:CGSize = UIScreen.mainScreen().bounds.size
            self.executeButton = MonitorButton(frame: CGRectMake(deviceSize.width - 100.0, 20.0, 72.0, 49.0))
            let frameworkBundle = NSBundle(forClass: ViewMonitor.self)
            if let buttonPath = frameworkBundle.pathForResource("button", ofType: "png"),let buttonImage = UIImage(named: buttonPath){
                self.executeButton?.setBackgroundImage(buttonImage, forState: UIControlState.Normal)
            }else if let buttonImage = UIImage(named: "button"){
                self.executeButton?.setBackgroundImage(buttonImage, forState: UIControlState.Normal)
            }else{
                self.executeButton?.setBackgroundImage(createImageFromUIColor(UIColor.blackColor()), forState: UIControlState.Normal)
            }
            if let selectedButtonPath = frameworkBundle.pathForResource("button_selected", ofType: "png"),let buttonSelectedImage = UIImage(named: selectedButtonPath){
                self.executeButton?.setBackgroundImage(buttonSelectedImage, forState: UIControlState.Selected)
            }else if let buttonSelectedImage = UIImage(named: "button_selected"){
                self.executeButton?.setBackgroundImage(buttonSelectedImage, forState: UIControlState.Selected)
            }else{
                self.executeButton?.setBackgroundImage(createImageFromUIColor(UIColor.redColor()), forState: UIControlState.Selected)
            }
            self.executeButton?.addTarget(self, action: "manualExecute:", forControlEvents: UIControlEvents.TouchUpInside)

            let pan = UIPanGestureRecognizer(target: self, action: "dragEvent:")
            self.executeButton?.addGestureRecognizer(pan)
            if let executeButton = self.executeButton{
                rootView?.addSubview(executeButton)
                rootView?.bringSubviewToFront(executeButton)
            }
            return
        }
        rootView?.addSubview(executeButton)
        rootView?.bringSubviewToFront(executeButton)
    }

    @objc private func dragEvent(sender:UIPanGestureRecognizer){
        let diff = sender.translationInView(rootView)
        let center = CGPointMake(sender.view!.center.x + diff.x, sender.view!.center.y + diff.y)
        sender.view?.center = center
        sender.setTranslation(CGPointZero, inView: rootView)
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
        self.infoView = InfoView(frame: CGRect(x: deviceSize.width - 220.0, y: 70.0, width: 200.0, height: 180.0))
        let color = UIColor.blackColor()
        let alphaColor = color.colorWithAlphaComponent(0.6)
        self.infoView!.backgroundColor = alphaColor
        self.infoView!.hidden = true
        let pan = UIPanGestureRecognizer(target: self, action: "dragEvent:")
        self.infoView!.addGestureRecognizer(pan)
        rootView?.addSubview(self.infoView!)
        rootView?.bringSubviewToFront(self.infoView!)
    }

    private func deleteAllMonitorViews(){
        let _ = buttons.map(){ $0.removeFromSuperview() }
        buttons.removeAll(keepCapacity: false)
    }

    private func analyzeAllViews(){
        analyzeView(rootView)
    }

    private func analyzeView(view:UIView?){
        guard let view = view else{
            return
        }
        
        if checkRejectView(view){
            return
        }
        drawViewOn(view)

        //to get child views
        let childViews = view.subviews
        if childViews.isEmpty{
            return
        }
        let _ = childViews.map(){ analyzeView($0) }
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
                enabledViews.append(view)
                view.userInteractionEnabled = true
            }
            view.addSubview(button)
        }
    }

    private func resetAllInteractionEnabled(){
        let _ = enabledViews.map(){ $0.userInteractionEnabled = false }
        enabledViews.removeAll(keepCapacity: false)
    }

    //true: targetList include view
    private func checkTargetView(view:UIView) -> Bool{
        if view is UILabel ||  view is UIImageView || view is UIButton{
            return true
        }
        
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
                sender.layer.borderWidth = 2.0
                sender.layer.borderColor = UIColor.redColor().CGColor
            }
            let _ = buttons.filter(){ $0 !== sender}.map(){ $0.layer.borderWidth = 0.0; $0.selected = false }
        }
    }
    
    private func hexStr(var hexStr : NSString, alpha : CGFloat) -> UIColor {
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
    
    private class func monitor_methodSwizzling_exchange(fromSelector fromSelector: Selector, toSelector: Selector) {
        let fromMethod = class_getInstanceMethod(UIViewController.self, fromSelector)
        let toMethod = class_getInstanceMethod(UIViewController.self, toSelector)
        method_exchangeImplementations(fromMethod, toMethod)
    }
    
    func monitor_methodSwizzling_viewDidAppear(animated: Bool) {
        monitor_methodSwizzling_viewDidAppear(animated)
        ViewMonitor.detectedViewDidAppear(self)
    }
}
