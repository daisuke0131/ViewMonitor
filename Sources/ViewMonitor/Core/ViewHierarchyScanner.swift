import UIKit

/// ビュー階層を走査して計測対象を集める。
/// UIKit ビューに加え、ホスティングビュー配下は SwiftUI のアクセシビリティ要素を集める。
struct ViewHierarchyScanner {

    let configuration: MonitorConfiguration

    private let accessibilityScanner = AccessibilityElementScanner()

    /// ホスティングビュー判定。実体はクラス名照合のみだが、テストで差し替えられるよう注入可能にする。
    private let isHostingView: @MainActor (UIView) -> Bool

    init(
        configuration: MonitorConfiguration = .default,
        isHostingView: @escaping @MainActor (UIView) -> Bool = { ViewHierarchyScanner.isDefaultHostingView($0) }
    ) {
        self.configuration = configuration
        self.isHostingView = isHostingView
    }

    /// SwiftUI のホスティングビューかどうか。
    /// `_UIHostingView<Content>` はジェネリッククラスで `NSStringFromClass` がマングル名を
    /// 返すため、`String(describing:)` のプレフィックスで判定する。プライベート API は呼ばない。
    static func isDefaultHostingView(_ view: UIView) -> Bool {
        String(describing: type(of: view)).hasPrefix("_UIHostingView")
    }

    /// `root` を含む階層から計測対象を深さ優先で集める。
    /// 除外対象のビューに達した時点で、その子孫は走査しない。
    @MainActor
    func measurementTargets(in root: UIView) -> [MeasurementTarget] {
        guard !isRejected(root) else {
            return []
        }
        var result: [MeasurementTarget] = []
        if isTarget(root) {
            result.append(.uiKitView(root))
        }
        if isHostingView(root) {
            result.append(
                contentsOf: accessibilityScanner.targets(in: root).map { .accessibilityElement($0) }
            )
        }
        for subview in root.subviews {
            result.append(contentsOf: measurementTargets(in: subview))
        }
        return result
    }

    /// `root` を含む階層から計測対象の UIKit ビューだけを集める。
    @MainActor
    func targets(in root: UIView) -> [UIView] {
        measurementTargets(in: root).compactMap { target in
            if case .uiKitView(let view) = target {
                return view
            }
            return nil
        }
    }

    /// 計測対象かどうか。
    @MainActor
    func isTarget(_ view: UIView) -> Bool {
        if view is UILabel || view is UIImageView || view is UIButton {
            return true
        }
        return configuration.additionalTargetClassNames.contains(Self.className(of: view))
    }

    /// 走査から除外するかどうか。
    @MainActor
    func isRejected(_ view: UIView) -> Bool {
        if view.tag == configuration.rejectedTag {
            return true
        }
        return configuration.rejectedClassNames.contains(Self.className(of: view))
    }

    /// モジュール名を除いたクラス名を返す。
    /// KVO がオブジェクトを動的にサブクラス化すると `type(of:)` は
    /// `NSKVONotifying_UITabBar` のような合成クラスを返してしまい、
    /// `rejectedClassNames` と一致しなくなる。`classForCoder` はその
    /// 実装詳細を隠し、本来のクラスに正規化して返す。
    static func className(of object: AnyObject) -> String {
        let objectClass: AnyClass = (object as? NSObject)?.classForCoder ?? type(of: object)
        return NSStringFromClass(objectClass).components(separatedBy: ".").last ?? ""
    }
}
