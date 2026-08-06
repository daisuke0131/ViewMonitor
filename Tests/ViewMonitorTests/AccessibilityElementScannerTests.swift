import Testing
import UIKit
@testable import ViewMonitor

@Suite("AccessibilityElementScanner")
@MainActor
struct AccessibilityElementScannerTests {

    private let scanner = AccessibilityElementScanner()

    private func makeElement(
        in container: UIView,
        traits: UIAccessibilityTraits,
        label: String? = nil
    ) -> UIAccessibilityElement {
        let element = UIAccessibilityElement(accessibilityContainer: container)
        element.isAccessibilityElement = true
        element.accessibilityTraits = traits
        element.accessibilityLabel = label
        return element
    }

    @Test("staticText / image / button の要素を種別名付きで集める")
    func collectsElementsWithKinds() {
        let host = UIView()
        let text = makeElement(in: host, traits: .staticText, label: "Hello")
        let image = makeElement(in: host, traits: .image)
        let button = makeElement(in: host, traits: .button)
        host.accessibilityElements = [text, image, button]

        let targets = scanner.targets(in: host)

        #expect(targets.map(\.kind) == ["Text", "Image", "Button"])
        #expect(targets[0].element === text)
        #expect(targets[0].hostingView === host)
    }

    @Test("複合 traits は button > image > staticText の優先順で1つに決める")
    func prefersButtonOverText() {
        let host = UIView()
        let element = makeElement(in: host, traits: [.button, .staticText], label: "Tap")
        host.accessibilityElements = [element]

        #expect(scanner.targets(in: host).map(\.kind) == ["Button"])
    }

    @Test("対象外 traits のみの要素は集めない")
    func ignoresUnrelatedTraits() {
        let host = UIView()
        host.accessibilityElements = [makeElement(in: host, traits: .adjustable)]

        #expect(scanner.targets(in: host).isEmpty)
    }

    @Test("入れ子のコンテナ要素を再帰的に走査する")
    func collectsNestedElements() {
        let host = UIView()
        let container = UIAccessibilityElement(accessibilityContainer: host)
        container.isAccessibilityElement = false
        let leaf = makeElement(in: host, traits: .staticText, label: "Nested")
        container.accessibilityElements = [leaf]
        host.accessibilityElements = [container]

        let targets = scanner.targets(in: host)

        #expect(targets.count == 1)
        #expect(targets[0].element === leaf)
    }

    @Test("UIView の要素はスキップする(subview 走査との二重検出を防ぐ)")
    func skipsUIViewElements() {
        let host = UIView()
        let label = UILabel()
        label.accessibilityTraits = .staticText
        host.accessibilityElements = [label]

        #expect(scanner.targets(in: host).isEmpty)
    }

    @Test("accessibilityElements が nil なら空を返す")
    func returnsEmptyForNilElements() {
        #expect(scanner.targets(in: UIView()).isEmpty)
    }
}
