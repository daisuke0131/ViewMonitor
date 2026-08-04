import UIKit

/// ビュー階層を走査して計測対象のビューを集める。
struct ViewHierarchyScanner {

    let configuration: MonitorConfiguration

    init(configuration: MonitorConfiguration = .default) {
        self.configuration = configuration
    }

    /// `root` を含む階層から計測対象のビューを深さ優先で集める。
    /// 除外対象のビューに達した時点で、その子孫は走査しない。
    @MainActor
    func targets(in root: UIView) -> [UIView] {
        guard !isRejected(root) else {
            return []
        }
        var result: [UIView] = []
        if isTarget(root) {
            result.append(root)
        }
        for subview in root.subviews {
            result.append(contentsOf: targets(in: subview))
        }
        return result
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
    static func className(of object: AnyObject) -> String {
        NSStringFromClass(type(of: object)).components(separatedBy: ".").last ?? ""
    }
}
