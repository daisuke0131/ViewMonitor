//
//  MonitorHostingController.swift
//  ViewMonitor
//

import SwiftUI
import UIKit

/// ViewMonitor 自身が内部で使うビューコントローラの目印。
///
/// ViewMonitor は `viewDidAppear` の swizzling でアプリの画面遷移を検知するが、
/// 自前の UI が発火させた `viewDidAppear` まで画面遷移として扱うと、表示した
/// ばかりのオーバーレイを自分で畳んでしまう。この目印が付いたビューコントローラは
/// 検知対象から外す。
///
/// `UIHostingController` 自体を目印にはできない。アプリ側の SwiftUI 画面まで
/// 巻き込み、本来検知すべき画面遷移を取りこぼすため。
@MainActor
protocol MonitorInternalViewController: UIViewController {}

/// InfoView の描画に使うホスティングコントローラ。
/// ViewMonitor 内部のものだと判別できるよう専用の型にしている。
final class MonitorHostingController<Content: View>:
    UIHostingController<Content>, MonitorInternalViewController {}
