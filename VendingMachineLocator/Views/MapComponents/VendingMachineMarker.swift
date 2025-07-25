import SwiftUI

/// 自動販売機マーカービュー
struct VendingMachineMarker: View {
    let machineType: MachineType
    let operatingStatus: OperatingStatus
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Image(systemName: machineType.icon)
                .font(.title2)
                .foregroundColor(.white)
                .padding(8)
                .background(operatingStatus == .operating ? machineType.color : operatingStatus.color)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(.white, lineWidth: 2)
                )
        }
        .buttonStyle(VendingMachineMarkerButtonStyle())
        .accessibilityLabel("\(machineType.rawValue)の自動販売機")
        .accessibilityHint("タップして詳細を表示")
    }
}

/// 自動販売機マーカーボタンスタイル
struct VendingMachineMarkerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    VendingMachineMarker(
        machineType: .beverage,
        operatingStatus: .operating,
        onTap: {}
    )
}