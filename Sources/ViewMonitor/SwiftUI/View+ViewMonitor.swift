import SwiftUI

public extension View {

    /// SwiftUI ライフサイクルのアプリで ViewMonitor を起動する。
    ///
    ///     WindowGroup {
    ///         ContentView()
    ///             .viewMonitor()
    ///     }
    ///
    /// 起動済みなら何もしないため、複数回 appear しても無害。
    func viewMonitor() -> some View {
        onAppear {
            ViewMonitor.start()
        }
    }
}
