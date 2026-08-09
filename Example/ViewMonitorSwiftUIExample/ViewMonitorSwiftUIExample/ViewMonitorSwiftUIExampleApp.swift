import SwiftUI
import ViewMonitor

@main
struct ViewMonitorSwiftUIExampleApp: App {

    init() {
        // SwiftUI 要素の検出はアクセシビリティツリーに依存し、iOS は
        // アクセシビリティクライアント接続中しかツリーを構築しない。
        // DEBUG ビルド限定の API でプロセス内から構築を有効化する
        // (リリースビルドでは何もしない)。
        ViewMonitor.enableSwiftUIElementDetection()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .viewMonitor()
        }
    }
}
