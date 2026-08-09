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

    @Test("実物の List の行も検出される")
    func detectsRowsInsideRealList() async throws {
        // List はホスティングビューの下に UICollectionView を挟み、行の AX 要素は
        // 各セル内の CellHostingView が公開する。ホスティングビュー直属の配列
        // だけを読む実装だと行が1つも検出されない(実機で報告された症状)。
        try #require(ViewMonitor.enableSwiftUIElementDetection())

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let host = UIHostingController(rootView: List(0..<5, id: \.self) { index in
            Text("Row \(index)")
        })
        window.rootViewController = host
        window.makeKeyAndVisible()
        window.layoutIfNeeded()

        // セルの生成もツリーの構築も非同期のため、時間切れまでポーリングする。
        let scanner = ViewHierarchyScanner()
        var rowTexts: [String] = []
        for _ in 0..<100 where rowTexts.count < 5 {
            window.layoutIfNeeded()
            rowTexts = scanner.measurementTargets(in: window).compactMap { target in
                guard case .accessibilityElement(let info) = target, info.kind == "Text" else {
                    return nil
                }
                return (info.element?.accessibilityLabel).flatMap { $0.hasPrefix("Row ") ? $0 : nil }
            }
            if rowTexts.count >= 5 {
                break
            }
            try await Task.sleep(nanoseconds: 100_000_000)
        }

        #expect(rowTexts.count >= 5, "detected rows: \(rowTexts)")
        window.isHidden = true
    }
}
