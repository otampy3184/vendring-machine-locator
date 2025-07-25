import SwiftUI

/// 長押しエフェクトビュー
struct LongPressEffectView: View {
    let location: CGPoint
    let progress: Double
    
    var body: some View {
        Circle()
            .stroke(Color.blue.opacity(0.4), lineWidth: 2)
            .frame(width: 40 + (progress * 30), height: 40 + (progress * 30))
            .opacity(1 - progress * 0.6)
            .position(location)
            .animation(.easeInOut(duration: 0.2), value: progress)
    }
}

#Preview {
    LongPressEffectView(location: CGPoint(x: 100, y: 100), progress: 0.5)
}