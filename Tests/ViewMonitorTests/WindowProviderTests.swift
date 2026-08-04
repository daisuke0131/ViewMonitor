import Testing
import UIKit
@testable import ViewMonitor

@Suite("WindowProvider")
@MainActor
struct WindowProviderTests {

    /// `WindowProvider.keyWindow` は「フォアグラウンドで有効なシーンを優先する」という
    /// 選択ロジックを持つが、この優先順位そのものは複数シーンを同時に接続できる
    /// 実行中のアプリでしか検証できず、このテストバンドルでは再現できない。
    /// ここで保証できるのは、どの実行環境でも成り立つはずの契約 ——
    /// 返ってきた window は必ず現在接続中のいずれかの window scene に属する
    /// （あるいは、どのシーンも keyWindow を持たないなら nil を返す）——
    /// という部分に限られる。
    ///
    /// 実際にこのテストバンドル（ホストアプリを持たないライブラリのユニット
    /// テスト）で実行すると `UIApplication.shared.connectedScenes` は空になり、
    /// `WindowProvider.keyWindow` は常に nil を返す。つまりこのテストは常に
    /// 上の guard の nil 分岐（`scenes.allSatisfy { ... }` は空集合に対して
    /// 自明に真）を通る。非 nil 側の `scenes.contains { ... }` は、接続済み
    /// シーンを持つ実行環境（例えばホストアプリ付きの UI テストターゲット）
    /// で動かさない限り、このスイートでは一度も実行されない。
    @Test("返す window は必ず接続中の window scene に属する")
    func returnedWindowBelongsToAConnectedScene() {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }

        guard let window = WindowProvider.keyWindow else {
            // シーンが無い、あるいはどのシーンも keyWindow を持たない実行環境では nil が正しい。
            #expect(scenes.allSatisfy { $0.keyWindow == nil })
            return
        }
        #expect(scenes.contains { $0 === window.windowScene })
    }
}
