import SwiftUI
import Testing
import UIKit
@testable import ViewMonitor

/// 実物の `UIHostingController` が公開するアクセシビリティツリーに対する
/// エンドツーエンドの検出テスト。
///
/// iOS はアクセシビリティクライアントが接続している間しかツリーを構築しない
/// ため、素のユニットテスト環境ではこの検証ができなかった(過去に同種のテストが
/// 2連続で要素0件になり削除されている)。`enableSwiftUIElementDetection()` で
/// プロセス内からツリー構築を有効化できるようになったので、フェイクではなく
/// SwiftUI が実際に生成する要素で検出経路全体を検証する。
@Suite("SwiftUI element detection (real accessibility tree)", .serialized)
@MainActor
struct SwiftUIElementDetectionTests {

    @Test("有効化後、実物のホスティングビューから Text / Image / Button が検出される")
    func detectsRealSwiftUIElements() async throws {
        // DEBUG ビルド(テストは常に該当)で有効化できること自体も検証対象。
        try #require(ViewMonitor.enableSwiftUIElementDetection())

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let host = UIHostingController(rootView: VStack {
            Text("Hello, ViewMonitor!")
            Image(systemName: "viewfinder")
            Button("Tap me") {}
        })
        window.rootViewController = host
        window.makeKeyAndVisible()
        window.layoutIfNeeded()

        // ツリーは有効化後に非同期で構築されるため、時間切れまでポーリングする。
        // 固定スリープ1回だと CI の遅い環境で不安定になる。
        let scanner = ViewHierarchyScanner()
        var kinds: Set<String> = []
        for _ in 0..<100 where !kinds.isSuperset(of: ["Text", "Image", "Button"]) {
            kinds = Set(
                scanner.measurementTargets(in: window).compactMap { target in
                    if case .accessibilityElement(let info) = target {
                        return info.kind
                    }
                    return nil
                }
            )
            if kinds.isSuperset(of: ["Text", "Image", "Button"]) {
                break
            }
            try await Task.sleep(nanoseconds: 100_000_000)
        }

        #expect(kinds.isSuperset(of: ["Text", "Image", "Button"]))
        window.isHidden = true
    }
}
