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
        var seenElements = Set<ObjectIdentifier>()
        return collectTargets(in: root, underHostingView: false, seenElements: &seenElements)
    }

    /// SwiftUI の List はホスティングビューの下に UICollectionView を挟み、
    /// 行の AX 要素は各セル内の CellHostingView(クラス名が `_UIHostingView`
    /// 接頭辞に一致しない)が公開する。ホスティングビュー直属の配列だけを
    /// 読むと行が1つも検出されないため、ホスティングビュー配下に入ったら
    /// すべてのビューの AX 要素を読む。ホスティングビューを含まない
    /// 純 UIKit の階層では従来どおり AX 走査を行わない。
    /// 同じ要素が複数のビューから公開された場合に備え、要素単位で重複を除く。
    @MainActor
    private func collectTargets(
        in root: UIView,
        underHostingView: Bool,
        seenElements: inout Set<ObjectIdentifier>
    ) -> [MeasurementTarget] {
        guard !isRejected(root) else {
            return []
        }
        var result: [MeasurementTarget] = []
        if isTarget(root) {
            result.append(.uiKitView(root))
        }
        let inHostingSubtree = underHostingView || isHostingView(root)
        if inHostingSubtree {
            for info in accessibilityScanner.targets(in: root) {
                guard let element = info.element, seenElements.insert(ObjectIdentifier(element)).inserted else {
                    continue
                }
                result.append(.accessibilityElement(info))
            }
        }
        for subview in root.subviews {
            result.append(
                contentsOf: collectTargets(
                    in: subview, underHostingView: inHostingSubtree, seenElements: &seenElements
                )
            )
        }
        return result
    }

    /// `root` を含む階層にホスティングビューがあるか。
    /// SwiftUI 要素が「検出できて0件」なのか「そもそも SwiftUI が無い」のかを
    /// 呼び出し側が区別するために使う。除外規則は measurementTargets と揃える。
    @MainActor
    func hasHostingView(in root: UIView) -> Bool {
        guard !isRejected(root) else {
            return false
        }
        if isHostingView(root) {
            return true
        }
        return root.subviews.contains { hasHostingView(in: $0) }
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
