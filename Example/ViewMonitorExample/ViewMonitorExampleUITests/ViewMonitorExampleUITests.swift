import XCTest

/// UIKit ライフサイクルのサンプルに対する実タッチ経路の回帰テスト。
/// 検証の観点は SwiftUI 側(ViewMonitorUITests)と同じで、UIKit だけの
/// 経路(storyboard のビュー階層、SceneDelegate からの起動)でも
/// 計測と回転時の挙動が成り立つことを押さえる。
final class ViewMonitorExampleUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        // 回転テスト後もシミュレータの向きは残るため、各テストを縦から始める。
        XCUIDevice.shared.orientation = .portrait
    }

    /// アプリを起動し、実行ボタンをタップして計測を開始する。
    private func launchAndStartMeasuring(_ app: XCUIApplication) {
        app.launch()
        let launcher = app.buttons["ViewMonitor.launcher"]
        XCTAssertTrue(launcher.waitForExistence(timeout: 10), "実行ボタンが表示されない")
        launcher.tap()
        let monitorButton = app.buttons.matching(identifier: "ViewMonitor.monitorButton").firstMatch
        XCTAssertTrue(monitorButton.waitForExistence(timeout: 5), "トグルONで計測ボタンが出ない")
    }

    func testMeasuresLabelViaRealTap() {
        let app = XCUIApplication()
        launchAndStartMeasuring(app)

        let label = app.staticTexts["ViewMonitor Library"]
        XCTAssertTrue(label.exists, "ラベルが見つからない")
        label.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        XCTAssertTrue(
            app.staticTexts["class: UILabel"].waitForExistence(timeout: 5),
            "UILabel の計測結果が InfoView に出ない"
        )
    }

    func testRotationKeepsMeasuringAndLauncherStaysOnScreen() {
        let app = XCUIApplication()
        launchAndStartMeasuring(app)

        // 横 → 縦の順で確認する。orientationDidChange はウィンドウのリサイズ
        // 完了前に届くため、旧 bounds で配置すると縦復帰時に実行ボタンが
        // 画面外へ出る(SwiftUI 側と共通の退行検出)。
        for orientation in [UIDeviceOrientation.landscapeLeft, .portrait] {
            XCUIDevice.shared.orientation = orientation

            let launcher = app.buttons["ViewMonitor.launcher"]
            XCTAssertTrue(launcher.waitForExistence(timeout: 5))
            XCTAssertTrue(launcher.isSelected, "回転で計測が OFF に戻ってしまった (\(orientation.rawValue))")

            let window = app.windows.firstMatch.frame
            XCTAssertTrue(
                window.contains(launcher.frame),
                "実行ボタンが画面外に出た (\(orientation.rawValue)): launcher=\(launcher.frame) window=\(window)"
            )
            XCTAssertTrue(
                app.buttons.matching(identifier: "ViewMonitor.monitorButton").firstMatch.exists,
                "回転後に再スキャンされていない (\(orientation.rawValue))"
            )
        }
    }
}
