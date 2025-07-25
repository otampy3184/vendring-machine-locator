import SwiftUI

/// トップナビゲーションバー
struct TopNavigationBar: View {
    let onDrawerTap: () -> Void
    
    var body: some View {
        HStack {
            NavigationButton(icon: "line.horizontal.3", action: onDrawerTap)
            
            Spacer()
            
            Text("自販機まっぷ")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            // 右側のスペーサー（バランスを保つため）
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.regularMaterial)
    }
}

#Preview {
    TopNavigationBar(onDrawerTap: {})
}