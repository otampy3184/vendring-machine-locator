import SwiftUI
import CoreLocation

/// 自動販売機リストビュー
struct VendingMachineList: View {
    let vendingMachines: [VendingMachine]
    let currentLocation: CLLocation?
    let onDelete: ((VendingMachine) -> Void)?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(vendingMachines) { vendingMachine in
                    VendingMachineCardView(
                        vendingMachine: vendingMachine,
                        currentLocation: currentLocation,
                        onDelete: onDelete
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 8)
        }
        .background(.clear)
    }
}

#Preview {
    VendingMachineList(
        vendingMachines: [],
        currentLocation: nil,
        onDelete: nil
    )
}