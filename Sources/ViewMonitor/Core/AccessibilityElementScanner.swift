import UIKit

/// ホスティングビューのアクセシビリティ要素ツリーを走査して SwiftUI 要素を集める。
/// SwiftUI の Text / Image / Button は UIKit ビューを生成しないため、
/// VoiceOver 向けに公開されるアクセシビリティ要素を計測対象として使う。
struct AccessibilityElementScanner {

    /// `hostingView` 配下のアクセシビリティ要素から計測対象を集める。
    @MainActor
    func targets(in hostingView: UIView) -> [AccessibilityElementInfo] {
        collect(from: hostingView.accessibilityElements ?? [], hostingView: hostingView)
    }

    @MainActor
    private func collect(from elements: [Any], hostingView: UIView) -> [AccessibilityElementInfo] {
        var result: [AccessibilityElementInfo] = []
        for case let element as NSObject in elements {
            // UIView は subview 走査が拾うため、二重検出を防いでスキップする。
            if element is UIView {
                continue
            }
            if element.isAccessibilityElement, let kind = Self.kind(of: element.accessibilityTraits) {
                result.append(
                    AccessibilityElementInfo(element: element, hostingView: hostingView, kind: kind)
                )
            }
            result.append(
                contentsOf: collect(from: element.accessibilityElements ?? [], hostingView: hostingView)
            )
        }
        return result
    }

    /// traits から種別表示名を決める。対象外の traits は nil。
    /// 複合 traits(ボタン内テキスト等)は button > image > staticText の優先順。
    static func kind(of traits: UIAccessibilityTraits) -> String? {
        if traits.contains(.button) {
            return "Button"
        }
        if traits.contains(.image) {
            return "Image"
        }
        if traits.contains(.staticText) {
            return "Text"
        }
        return nil
    }
}
