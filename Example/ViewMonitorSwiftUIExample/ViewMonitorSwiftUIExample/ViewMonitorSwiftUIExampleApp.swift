import SwiftUI
import ViewMonitor

@main
struct ViewMonitorSwiftUIExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .viewMonitor()
        }
    }
}
