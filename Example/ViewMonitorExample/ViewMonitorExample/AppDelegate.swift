//
//  AppDelegate.swift
//  ViewMonitorExample
//

import UIKit
import ViewMonitor


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func applicationDidFinishLaunching(_ application: UIApplication) {
        ViewMonitor.start()
    }

}

