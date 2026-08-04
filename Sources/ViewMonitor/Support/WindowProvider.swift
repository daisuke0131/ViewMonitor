//
//  WindowProvider.swift
//  ViewMonitor
//

import UIKit

/// シーン対応の keyWindow を取得する。
enum WindowProvider {

    /// フォアグラウンドで有効なシーンの keyWindow を返す。
    /// 有効なシーンが無い場合は接続中の最初のシーンを使う。
    @MainActor
    static var keyWindow: UIWindow? {
        let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let activeScene = windowScenes.first { $0.activationState == .foregroundActive }
        return (activeScene ?? windowScenes.first)?.keyWindow
    }
}
