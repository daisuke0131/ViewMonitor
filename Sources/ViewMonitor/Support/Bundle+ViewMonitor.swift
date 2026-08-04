//
//  Bundle+ViewMonitor.swift
//  ViewMonitor
//

import UIKit

extension Bundle {
    /// リソースバンドルを解決する。
    /// SPM では `Bundle.module`、CocoaPods では `resource_bundles` が生成する
    /// `ViewMonitor.bundle` を返す。どちらも見つからない場合はフレームワーク自身を返す。
    static var viewMonitor: Bundle {
        #if SWIFT_PACKAGE
        return .module
        #else
        let base = Bundle(for: ViewMonitor.self)
        if let url = base.url(forResource: "ViewMonitor", withExtension: "bundle"),
           let bundle = Bundle(url: url) {
            return bundle
        }
        return base
        #endif
    }
}
