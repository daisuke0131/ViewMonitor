//
//  SceneDelegate.swift
//  ViewMonitorExample
//

import UIKit
import ViewMonitor

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        // ウィンドウが接続された直後に開始する。
        // 以降の画面遷移は viewDidAppear の swizzling で検知される。
        ViewMonitor.start()
    }
}
