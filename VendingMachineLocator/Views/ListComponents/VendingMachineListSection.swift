import SwiftUI
import CoreLocation

/// 自動販売機リストセクション
struct VendingMachineListSection: View {
    let vendingMachines: [VendingMachine]
    let currentLocation: CLLocation?
    let onDelete: ((VendingMachine) -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            VendingMachineListHeader(count: vendingMachines.count)
            
            // コンテンツエリア
            if vendingMachines.isEmpty {
                VendingMachineEmptyState()
            } else {
                VendingMachineList(
                    vendingMachines: vendingMachines, 
                    currentLocation: currentLocation,
                    onDelete: onDelete
                )
            }
        }
        .background(.thinMaterial)
    }
}

#Preview {
    VendingMachineListSection(
        vendingMachines: [],
        currentLocation: nil,
        onDelete: nil
    )
}