import SwiftUI

struct ContentView: View {
    var body: some View {
        // iOS 15 対応のため NavigationStack ではなく NavigationView を使う。
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Hello, ViewMonitor!")
                    .font(.title2)
                Image(systemName: "viewfinder")
                    .font(.system(size: 48))
                Button("Tap me") {}
                    .buttonStyle(.bordered)
                NavigationLink("Show List") {
                    ListScreen()
                }
                Spacer()
            }
            .padding()
            .navigationTitle("SwiftUI Example")
        }
        .navigationViewStyle(.stack)
    }
}

/// スクロール時の計測ボタン非追従(既知の制限)を確認するための画面。
struct ListScreen: View {
    var body: some View {
        List(0..<30, id: \.self) { index in
            Text("Row \(index)")
        }
        .navigationTitle("List")
    }
}
