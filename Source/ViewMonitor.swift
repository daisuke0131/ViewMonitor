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
        NotificationCenter.default.addObserver(self, selector: #selector(self.orientationChanged(notification:)), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    private func removeNotification(){
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    @objc private func orientationChanged(notification: NSNotification){
        if started{
            deleteInfoView()
            deleteExecuteButton()
            deleteAllMonitorViews()
            resetAllInteractionEnabled()
            rootView = UIApplication.shared.keyWindow
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
            sharedInstance.rootView = UIApplication.shared.keyWindow
            sharedInstance.addExecuteButton()
            sharedInstance.addInfoView()
        }
    }
    
    private func addExecuteButton(){
        guard let executeButton = executeButton else{
            let deviceSize:CGSize = UIScreen.main.bounds.size
            self.executeButton = MonitorButton(frame: CGRect(x: deviceSize.width - 100.0, y: 20.0, width: 72.0, height: 49.0))
            let frameworkBundle = Bundle(for: ViewMonitor.self)
            if let buttonPath = frameworkBundle.path(forResource: "button", ofType: "png"),let buttonImage = UIImage(named: buttonPath){
                self.executeButton?.setBackgroundImage(buttonImage, for: UIControl.State.normal)
            }else if let buttonImage = UIImage(named: "button"){
                self.executeButton?.setBackgroundImage(buttonImage, for: UIControl.State.normal)
            }else{
                self.executeButton?.setBackgroundImage(createImageFromUIColor(color: UIColor.black), for: UIControl.State.normal)
            }
            if let selectedButtonPath = frameworkBundle.path(forResource: "button_selected", ofType: "png"),let buttonSelectedImage = UIImage(named: selectedButtonPath){
                self.executeButton?.setBackgroundImage(buttonSelectedImage, for: UIControl.State.selected)
            }else if let buttonSelectedImage = UIImage(named: "button_selected"){
                self.executeButton?.setBackgroundImage(buttonSelectedImage, for: UIControl.State.selected)
            }else{
                self.executeButton?.setBackgroundImage(createImageFromUIColor(color: UIColor.red), for: UIControl.State.selected)
            }
            self.executeButton?.addTarget(self, action: #selector(self.manualExecute(sender:)), for: UIControl.Event.touchUpInside)

            let pan = UIPanGestureRecognizer(target: self, action: #selector(self.dragEvent(sender:)))
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
        let diff = sender.translation(in: rootView)
        let center = CGPoint(x: sender.view!.center.x + diff.x, y: sender.view!.center.y + diff.y)
        sender.view?.center = center
        sender.setTranslation(CGPoint.zero, in: rootView)
    }
    
    //execute
    @objc func manualExecute(sender:MonitorButton){
        sender.isSelected = !sender.isSelected
        if sender.isSelected{
            execute()
        }else{
            terminate()
        }
    }
    
    //make 100 * 100 information view
    // have to set tag to reject.
    private func addInfoView(){
        let deviceSize:CGSize = UIScreen.main.bounds.size
        self.infoView = InfoView(frame: CGRect(x: deviceSize.width - 220.0, y: 70.0, width: 200.0, height: 180.0))
        let color = UIColor.black
        let alphaColor = color.withAlphaComponent(0.6)
        self.infoView!.backgroundColor = alphaColor
        self.infoView!.isHidden = true
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.dragEvent(sender:)))
        self.infoView!.addGestureRecognizer(pan)
        rootView?.addSubview(self.infoView!)
        rootView?.bringSubviewToFront(self.infoView!)
    }

    private func deleteAllMonitorViews(){
        let _ = buttons.map(){ $0.removeFromSuperview() }
        buttons.removeAll(keepingCapacity: false)
    }

    private func analyzeAllViews(){
        analyzeView(view: rootView)
    }

    private func analyzeView(view:UIView?){
        guard let view = view else{
            return
        }
        
        if checkRejectView(view: view){
            return
        }
        drawViewOn(view: view)

        //to get child views
        let childViews = view.subviews
        if childViews.isEmpty{
            return
        }
        let _ = childViews.map(){ analyzeView(view: $0) }
    }

    private func drawViewOn(view:UIView){
        if checkTargetView(view: view){
            let button = MonitorButton(frame: CGRect(x: 0.0, y: 0.0, width: view.frame.size.width, height: view.frame.size.height))
            button.setBackgroundImage(createImageFromUIColor(color: hexStr(hexNStr: "#7ED321", alpha: 0.7)), for: UIControl.State.normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
            button.addTarget(self, action: #selector(self.openEditor(sender:)), for: UIControl.Event.touchUpInside)
            button.targetView = view
            button.alpha = 0.2
            buttons.append(button)
            if !view.isUserInteractionEnabled{
                enabledViews.append(view)
                view.isUserInteractionEnabled = true
            }
            view.addSubview(button)
        }
    }

    private func resetAllInteractionEnabled(){
        let _ = enabledViews.map(){ $0.isUserInteractionEnabled = false }
        enabledViews.removeAll(keepingCapacity: false)
    }

    //true: targetList include view
    private func checkTargetView(view:UIView) -> Bool{
        if view is UILabel ||  view is UIImageView || view is UIButton{
            return true
        }
        
        for className in targetClassNames {
            if let viewClass = NSStringFromClass(view.classForCoder).components(separatedBy:".").last, viewClass == className {
                return true
            }
        }
        return false
    }
    
    // true: notTargetList include view
    private func checkRejectView(view:UIView) -> Bool{
        for className in rejectClassNames {
            if let viewClass = NSStringFromClass(view.classForCoder).components(separatedBy:".").last, viewClass == className {
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
        sender.isSelected = !sender.isSelected
        if let infoView = infoView{
            if sender.isSelected{
                infoView.isHidden = false
                infoView.targetView = sender.targetView
                sender.layer.borderWidth = 2.0
                sender.layer.borderColor = UIColor.red.cgColor
            }
            let _ = buttons.filter(){ $0 !== sender}.map(){ $0.layer.borderWidth = 0.0; $0.isSelected = false }
        }
    }
    
    private func hexStr(hexNStr : NSString, alpha : CGFloat) -> UIColor {
        let hexString = hexNStr.replacingOccurrences(of: "#", with: "")
        let scanner = Scanner(string: hexString as String)
        var color: UInt32 = 0
        if scanner.scanHexInt32(&color) {
            let r = CGFloat((color & 0xFF0000) >> 16) / 255.0
            let g = CGFloat((color & 0x00FF00) >> 8) / 255.0
            let b = CGFloat(color & 0x0000FF) / 255.0
            return UIColor(red:r,green:g,blue:b,alpha:alpha)
        } else {
            return UIColor.white;
        }
    }
    
    private func createImageFromUIColor(color:UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let contextRef = UIGraphicsGetCurrentContext()
        contextRef!.setFillColor(color.cgColor)
        contextRef!.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
}

extension UIViewController{
    class func monitor_methodSwizzling_didAppearWillDisappear() {
        monitor_methodSwizzling_exchange(fromSelector: #selector(self.viewDidAppear(_:)), toSelector: #selector(self.monitor_methodSwizzling_viewDidAppear(animated:)))
    }
    
    private class func monitor_methodSwizzling_exchange(fromSelector: Selector, toSelector: Selector) {
        let fromMethod = class_getInstanceMethod(UIViewController.self, fromSelector)!
        let toMethod = class_getInstanceMethod(UIViewController.self, toSelector)!
        method_exchangeImplementations(fromMethod, toMethod)
    }
    
    @objc func monitor_methodSwizzling_viewDidAppear(animated: Bool) {
        monitor_methodSwizzling_viewDidAppear(animated: animated)
        ViewMonitor.detectedViewDidAppear(vc: self)
    }
}
