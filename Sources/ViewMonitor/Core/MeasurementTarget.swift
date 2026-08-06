import UIKit

/// 計測対象。UIKit ビューまたは SwiftUI のアクセシビリティ要素。
enum MeasurementTarget {
    case uiKitView(UIView)
    case accessibilityElement(AccessibilityElementInfo)
}

/// SwiftUI 要素1つ分の参照。
struct AccessibilityElementInfo {
    /// SwiftUI が生成するアクセシビリティノード。画面遷移で破棄されたら nil。
    weak var element: NSObject?
    /// この要素を含むホスティングビュー。座標変換と window 同一性判定に使う。
    weak var hostingView: UIView?
    /// traits 由来の種別表示名("Text" / "Image" / "Button")。
    let kind: String
}
