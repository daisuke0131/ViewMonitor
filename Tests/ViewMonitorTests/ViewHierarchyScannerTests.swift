import Testing
import UIKit
import SwiftUI
@testable import ViewMonitor

/// 追加対象クラスの指定を検証するためのテスト専用ビュー。
/// UIKit の複合コントロールと違い内部サブビューを持たないため、
/// 走査結果をそのまま比較できる。
final class ScannerProbeView: UIView {}

@Suite("ViewHierarchyScanner")
@MainActor
struct ViewHierarchyScannerTests {

    private let scanner = ViewHierarchyScanner()

    @Test("UILabel / UIImageView / UIButton を対象として集める")
    func collectsStandardTargets() {
        let root = UIView()
        let label = UILabel()
        let imageView = UIImageView()
        let button = UIButton()
        [label, imageView, button].forEach(root.addSubview)

        let targets = scanner.targets(in: root)

        #expect(targets.contains(label))
        #expect(targets.contains(imageView))
        #expect(targets.contains(button))
    }

    @Test("素の UIView は対象にしない")
    func ignoresPlainViews() {
        let root = UIView()
        root.addSubview(UIView())

        #expect(scanner.targets(in: root).isEmpty)
    }

    @Test("入れ子になった対象も集める")
    func collectsNestedTargets() {
        let root = UIView()
        let container = UIView()
        let label = UILabel()
        container.addSubview(label)
        root.addSubview(container)

        #expect(scanner.targets(in: root) == [label])
    }

    @Test("ルート自身が対象なら含める")
    func includesRootWhenItIsTarget() {
        let label = UILabel()

        #expect(scanner.targets(in: label) == [label])
    }

    @Test("除外クラスのビューを対象にしない")
    func rejectsExcludedClasses() {
        let root = UIView()
        root.addSubview(UINavigationBar())
        root.addSubview(UITabBar())
        root.addSubview(MonitorButton())

        #expect(scanner.targets(in: root).isEmpty)
    }

    @Test("除外クラスの子孫は走査しない")
    func skipsDescendantsOfRejectedViews() {
        let root = UIView()
        let navigationBar = UINavigationBar()
        navigationBar.addSubview(UILabel())
        root.addSubview(navigationBar)

        #expect(scanner.targets(in: root).isEmpty)
    }

    @Test("除外タグを持つビューを対象にしない")
    func rejectsTaggedViews() {
        let root = UIView()
        let label = UILabel()
        label.tag = MonitorConfiguration.default.rejectedTag
        root.addSubview(label)

        #expect(scanner.targets(in: root).isEmpty)
    }

    @Test("除外タグを持つビューの子孫も走査しない")
    func skipsDescendantsOfTaggedViews() {
        let root = UIView()
        let container = UIView()
        container.tag = MonitorConfiguration.default.rejectedTag
        container.addSubview(UILabel())
        root.addSubview(container)

        #expect(scanner.targets(in: root).isEmpty)
    }

    @Test("子を持たないビューでも空の結果を返す")
    func handlesEmptyHierarchy() {
        #expect(scanner.targets(in: UIView()).isEmpty)
    }

    @Test("追加の対象クラス名を指定すると対象になる")
    func honorsAdditionalTargetClassNames() {
        var configuration = MonitorConfiguration.default
        configuration.additionalTargetClassNames = ["ScannerProbeView"]
        let scanner = ViewHierarchyScanner(configuration: configuration)
        let root = UIView()
        let probe = ScannerProbeView()
        root.addSubview(probe)

        #expect(scanner.targets(in: root) == [probe])
    }

    @Test("追加指定がなければ対象にならない")
    func ignoresUnlistedClasses() {
        let root = UIView()
        root.addSubview(ScannerProbeView())

        #expect(scanner.targets(in: root).isEmpty)
    }

    @Test("モジュール名を除いたクラス名を返す")
    func stripsModuleNameFromClassName() {
        #expect(ViewHierarchyScanner.className(of: ScannerProbeView()) == "ScannerProbeView")
        #expect(ViewHierarchyScanner.className(of: UILabel()) == "UILabel")
    }

    @Test("ホスティングビュー配下のアクセシビリティ要素を統合して集める")
    func collectsAccessibilityTargetsFromHostingView() {
        let root = UIView()
        let label = UILabel()
        let hostingProbe = UIView()
        let element = UIAccessibilityElement(accessibilityContainer: hostingProbe)
        element.isAccessibilityElement = true
        element.accessibilityTraits = .staticText
        hostingProbe.accessibilityElements = [element]
        root.addSubview(label)
        root.addSubview(hostingProbe)
        let scanner = ViewHierarchyScanner(isHostingView: { $0 === hostingProbe })

        let targets = scanner.measurementTargets(in: root)

        let views = targets.compactMap { target -> UIView? in
            if case .uiKitView(let view) = target { return view }
            return nil
        }
        let elements = targets.compactMap { target -> AccessibilityElementInfo? in
            if case .accessibilityElement(let info) = target { return info }
            return nil
        }
        #expect(views == [label])
        #expect(elements.count == 1)
        #expect(elements[0].element === element)
        #expect(elements[0].hostingView === hostingProbe)
    }

    @Test("除外対象のホスティングビューは走査しない")
    func skipsRejectedHostingView() {
        let root = UIView()
        let hostingProbe = UIView()
        hostingProbe.tag = MonitorConfiguration.default.rejectedTag
        let element = UIAccessibilityElement(accessibilityContainer: hostingProbe)
        element.isAccessibilityElement = true
        element.accessibilityTraits = .staticText
        hostingProbe.accessibilityElements = [element]
        root.addSubview(hostingProbe)
        let scanner = ViewHierarchyScanner(isHostingView: { $0 === hostingProbe })

        #expect(scanner.measurementTargets(in: root).isEmpty)
    }

    @Test("既定のホスティングビュー判定は _UIHostingView を検出する")
    func detectsRealHostingView() {
        let hostingView = UIHostingController(rootView: Text("A")).view ?? UIView()

        #expect(ViewHierarchyScanner.isDefaultHostingView(hostingView))
        #expect(!ViewHierarchyScanner.isDefaultHostingView(UIView()))
    }
}
