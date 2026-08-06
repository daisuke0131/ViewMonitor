import SwiftUI

/// InfoRow の配列を描画するだけのビュー。行の組み立ては InfoRowBuilder が担う。
struct InfoRowsView: View {

    let rows: [InfoRow]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                Text("\(row.title): \(row.value)")
                    .font(.system(size: 11))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 10, leading: 22, bottom: 10, trailing: 10))
        // 浮動パネル内で safe area にレイアウトを動かされない。
        .ignoresSafeArea()
    }
}
