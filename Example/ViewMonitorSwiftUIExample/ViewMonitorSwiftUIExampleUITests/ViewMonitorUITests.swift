import XCTest

/// 実タッチ経路(XCUITest)での回帰テスト。
///
/// ユニットテストは `sendActions` や単発の `hitTest` で挙動を再現するが、
/// 実際のタッチ配送はそれらと一致しないことがある。実機で見つかった
/// 「トグルが ON にならない」「計測ボタンにタッチが届かない」系のバグは
/// いずれもこの層でしか捕まえられなかったため、主要フローを実タッチで
/// 検証する。XCUITest 自体がアクセシビリティクライアントとして接続する
/// ので、SwiftUI 要素の検出もテスト中は常に有効になる。
final class ViewMonitorUITests: XCTestCase {

    #if VIEWMONITOR_CAPTURE_DEMO
    private let isReadmeDemoCaptureEnabled = true
    #else
    private let isReadmeDemoCaptureEnabled = false
    #endif

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

    /// 要素の中心を座標タップする。計測ボタンが上に重なっている要素は
    /// hittable 扱いにならないことがあるため、`tap()` ではなく座標で叩く。
    private func tapCenter(of element: XCUIElement) {
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    /// README 用の収録時だけ、各状態を視認できる長さで保持する。
    private func pauseForDemo(_ seconds: TimeInterval) {
        Thread.sleep(forTimeInterval: seconds)
    }

    func testMeasuresUIKitNavigationTitleLabel() {
        let app = XCUIApplication()
        launchAndStartMeasuring(app)

        let title = app.staticTexts["SwiftUI Example"]
        XCTAssertTrue(title.exists, "ナビタイトルが見つからない")
        tapCenter(of: title)

        XCTAssertTrue(
            app.staticTexts["class: UILabel"].waitForExistence(timeout: 5),
            "UILabel の計測結果が InfoView に出ない"
        )
    }

    func testMeasuresSwiftUIText() {
        let app = XCUIApplication()
        launchAndStartMeasuring(app)

        let hello = app.staticTexts["Hello, ViewMonitor!"]
        XCTAssertTrue(hello.exists, "SwiftUI の Text が見つからない")
        tapCenter(of: hello)

        XCTAssertTrue(
            app.staticTexts["class: Text"].waitForExistence(timeout: 5),
            "SwiftUI Text の計測結果が InfoView に出ない"
        )
        XCTAssertTrue(app.staticTexts["text: Hello, ViewMonitor!"].exists)
    }

    /// 実際の SwiftUI 画面で起動・単体計測・2 View 間の距離計測を収録する。
    /// 通常の CI ではスキップし、README の GIF を再生成するときだけ実行する。
    func testReadmeDemoCapture() throws {
        try XCTSkipUnless(
            isReadmeDemoCaptureEnabled,
            "Build with OTHER_SWIFT_FLAGS=-DVIEWMONITOR_CAPTURE_DEMO to record the README demo."
        )

        let app = XCUIApplication()
        app.launch()

        // 計測を ON にすると元の要素が計測ボタンに覆われるため、先に座標を保存する。
        let hello = app.staticTexts["Hello, ViewMonitor!"]
        let button = app.buttons["Tap me"]
        XCTAssertTrue(hello.waitForExistence(timeout: 10))
        XCTAssertTrue(button.exists)
        let helloFrame = hello.frame
        let buttonFrame = button.frame
        pauseForDemo(0.5)

        let launcher = app.buttons["ViewMonitor.launcher"]
        XCTAssertTrue(launcher.waitForExistence(timeout: 10))
        launcher.tap()
        XCTAssertTrue(
            app.buttons.matching(identifier: "ViewMonitor.monitorButton")
                .firstMatch.waitForExistence(timeout: 5)
        )
        pauseForDemo(0.5)

        app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: helloFrame.midX, dy: helloFrame.midY))
            .tap()
        XCTAssertTrue(app.staticTexts["class: Text"].waitForExistence(timeout: 5))
        pauseForDemo(0.75)

        app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: buttonFrame.midX, dy: buttonFrame.midY))
            .tap()

        let gapRow = app.staticTexts.matching(
            NSPredicate(format: "label BEGINSWITH %@", "gapY:")
        ).firstMatch
        XCTAssertTrue(gapRow.waitForExistence(timeout: 5))
        pauseForDemo(1.5)
    }

    func testListRowsGetMonitorButtons() {
        let app = XCUIApplication()
        app.launch()

        // 計測 OFF の間は通常どおり遷移できる。
        let showList = app.buttons["Show List"]
        XCTAssertTrue(showList.waitForExistence(timeout: 10))
        showList.tap()
        XCTAssertTrue(app.staticTexts["Row 0"].waitForExistence(timeout: 5), "List 画面に遷移しない")

        // 遷移で実行ボタンは貼り直されるので、改めて取得してタップする。
        let launcher = app.buttons["ViewMonitor.launcher"]
        XCTAssertTrue(launcher.waitForExistence(timeout: 5))
        launcher.tap()

        let buttons = app.buttons.matching(identifier: "ViewMonitor.monitorButton")
        XCTAssertTrue(buttons.firstMatch.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(buttons.count, 5, "List の行に計測ボタンが出ていない")
    }

    func testRotationKeepsMeasuringAndLauncherStaysOnScreen() {
        let app = XCUIApplication()
        launchAndStartMeasuring(app)

        // 横 → 縦の順で確認する。orientationDidChange はウィンドウのリサイズ
        // 完了前に届くため、旧 bounds(横向きの幅)で実行ボタンを配置すると
        // 縦に戻したとき画面外へ出る、という報告があった。
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

    func testShieldBlocksAppInteractionWhileMeasuring() {
        let app = XCUIApplication()
        app.launch()

        // 計測を ON にすると要素が計測ボタンに覆われて AX スナップショットから
        // 引けなくなることがあるため、ON にする前に NavigationLink の位置を
        // 覚えておき、以降は座標でタップする。
        let showList = app.buttons["Show List"]
        XCTAssertTrue(showList.waitForExistence(timeout: 10))
        let showListFrame = showList.frame

        let launcher = app.buttons["ViewMonitor.launcher"]
        XCTAssertTrue(launcher.waitForExistence(timeout: 5))
        launcher.tap()
        let monitorButton = app.buttons.matching(identifier: "ViewMonitor.monitorButton").firstMatch
        XCTAssertTrue(monitorButton.waitForExistence(timeout: 5), "トグルONで計測ボタンが出ない")

        // NavigationLink は計測ボタンに覆われている: タップしても遷移せず、
        // 計測対象として選択される。
        app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: showListFrame.midX, dy: showListFrame.midY))
            .tap()

        XCTAssertTrue(
            app.staticTexts["class: Button"].waitForExistence(timeout: 5),
            "NavigationLink が計測対象として選択されない"
        )
        XCTAssertFalse(app.staticTexts["Row 0"].exists, "計測中なのに List へ遷移してしまった")
        XCTAssertTrue(app.staticTexts["SwiftUI Example"].exists, "元の画面に留まっていない")

        // 何も無い領域のタップも吸収される(アプリ側に届かない)。
        app.windows.firstMatch
            .coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85))
            .tap()
        XCTAssertTrue(app.staticTexts["SwiftUI Example"].exists)
        XCTAssertTrue(app.buttons["ViewMonitor.launcher"].isSelected, "トグルが OFF に戻ってしまった")
    }
}
