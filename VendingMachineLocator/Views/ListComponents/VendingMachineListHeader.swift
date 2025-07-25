import SwiftUI

/// 自動販売機リストヘッダー
struct VendingMachineListHeader: View {
    let count: Int
    
    var body: some View {
        HStack {
            Text("マップ上の自動販売機")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Text("\(count)件")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.secondary.opacity(0.1))
                .clipShape(Capsule())
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.thickMaterial)
    }
}

#Preview {
    VendingMachineListHeader(count: 5)
}