//
//  ViewMonitor.swift
//  ViewMonitor
//

import UIKit
import Foundation

@MainActor
public final class ViewMonitor: NSObject {

    static let shared = ViewMonitor()
    
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
    
    public static func start() {
        guard !shared.started else { return }
        shared.fookViewEvent()
        shared.setNotification()
        shared.started = true
    }

    public static func stop() {
        guard shared.started else { return }
        shared.terminate()
        shared.removeNotification()
        shared.started = false
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
            rootView = WindowProvider.keyWindow
            addExecuteButton()
        }
    }

    // swizzling viewDidAppear and viewWillDisappear
    private func fookViewEvent(){
        UIViewController.monitor_methodSwizzling_didAppearWillDisappear()
    }
    
    /// `viewDidAppear` の swizzling から呼ばれる。
    static func detectedViewDidAppear() {
        guard shared.started else { return }
        shared.deleteInfoView()
        shared.deleteExecuteButton()
        shared.deleteAllMonitorViews()
        shared.resetAllInteractionEnabled()
        shared.rootView = WindowProvider.keyWindow
        shared.addExecuteButton()
        shared.addInfoView()
    }
    
    private func addExecuteButton(){
        guard let executeButton = executeButton else{
            let deviceSize: CGSize = rootView?.bounds.size ?? .zero
            self.executeButton = MonitorButton(frame: CGRect(x: deviceSize.width - 100.0, y: 20.0, width: 72.0, height: 49.0))
            self.executeButton?.setBackgroundImage(
                ViewMonitorAsset.button ?? .monitorSolidColor(.black),
                for: .normal
            )
            self.executeButton?.setBackgroundImage(
                ViewMonitorAsset.buttonSelected ?? .monitorSolidColor(.red),
                for: .selected
            )
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
        let deviceSize: CGSize = rootView?.bounds.size ?? .zero
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
            button.setBackgroundImage(
                .monitorSolidColor(color(fromHex: "#7ED321", alpha: 0.7)),
                for: .normal
            )
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
    
    /// `#RRGGBB` または `RRGGBB` 形式の文字列を UIColor に変換する。
    /// 解釈できない場合は白を返す。
    private func color(fromHex hex: String, alpha: CGFloat) -> UIColor {
        var string = hex
        if string.hasPrefix("#") {
            string.removeFirst()
        }
        guard string.count == 6, let value = UInt32(string, radix: 16) else {
            return .white
        }
        let r = CGFloat((value & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((value & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(value & 0x0000FF) / 255.0
        return UIColor(red: r, green: g, blue: b, alpha: alpha)
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
        ViewMonitor.detectedViewDidAppear()
    }
}
