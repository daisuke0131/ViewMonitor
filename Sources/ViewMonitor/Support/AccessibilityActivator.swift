//
//  AccessibilityActivator.swift
//  ViewMonitor
//

#if DEBUG
import UIKit

/// プロセス内でアクセシビリティランタイムを有効化する。
///
/// iOS はアクセシビリティクライアント(VoiceOver / Accessibility Inspector /
/// UI テスト)が接続している間しかアクセシビリティツリーを構築しないため、
/// 素の状態では SwiftUI 要素の検出結果が常に空になる。ここで使う
/// `_AXSSetAutomationEnabled` は UI テストランナーが使うのと同じ仕組みで、
/// クライアント接続なしにツリーの構築を開始させる。
///
/// プライベート API のため DEBUG ビルドでのみコンパイルする。`#if DEBUG` で
/// ファイルごと除外することで、リリースビルドのバイナリにはシンボル名の
/// 文字列自体が残らない。
@MainActor
enum AccessibilityActivator {

    /// 有効化に成功したら true。シンボルが見つからない環境では false。
    /// dlopen のハンドルは閉じない(システムライブラリはプロセス存続中
    /// 常駐するため、解放する意味がない)。
    static func activate() -> Bool {
        guard let handle = dlopen("/usr/lib/libAccessibility.dylib", RTLD_NOW),
              let symbol = dlsym(handle, "_AXSSetAutomationEnabled") else {
            return false
        }
        typealias SetAutomationEnabled = @convention(c) (Bool) -> Void
        unsafeBitCast(symbol, to: SetAutomationEnabled.self)(true)
        return true
    }
}
#endif
