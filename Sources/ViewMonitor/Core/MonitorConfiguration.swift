import UIKit

/// 監視対象の判定と表示に使う設定値。
struct MonitorConfiguration {

    /// 走査から除外するクラス名。オーバーレイ自身とシステムのバーを含む。
    var rejectedClassNames: Set<String>

    /// 走査対象に加えるクラス名。
    /// UILabel / UIImageView / UIButton は指定不要で常に対象になる。
    var additionalTargetClassNames: Set<String>

    /// このタグを持つビューとその子孫は走査しない。
    var rejectedTag: Int

    /// 計測対象に重ねるオーバーレイの色。
    var overlayColorHex: String

    /// オーバーレイの不透明度。
    var overlayAlpha: CGFloat

    static let `default` = MonitorConfiguration(
        rejectedClassNames: [
            "MonitorButton",
            "MonitorLauncherButton",
            "InfoView",
            "UITabBar",
            "UINavigationBar",
            "_UILayoutGuide"
        ],
        additionalTargetClassNames: [],
        // 既存ユーザーがこのタグでビューを除外している可能性があるため値を変えない。
        rejectedTag: 5_292_739,
        overlayColorHex: "#7ED321",
        overlayAlpha: 0.7
    )
}
