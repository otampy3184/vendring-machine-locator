import SwiftUI

/// 自動販売機リスト空状態ビュー
struct VendingMachineEmptyState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.grid.2x2.slash")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("マップ上に自動販売機がありません")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.clear)
    }
}

#Preview {
    VendingMachineEmptyState()
}