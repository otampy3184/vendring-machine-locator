import SwiftUI

/// ナビゲーションボタンコンポーネント
struct NavigationButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .foregroundColor(.primary)
                .padding()
                .background(.regularMaterial, in: Circle())
        }
    }
}

#Preview {
    NavigationButton(icon: "location", action: {})
}