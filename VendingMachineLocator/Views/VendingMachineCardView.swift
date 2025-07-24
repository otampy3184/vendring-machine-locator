//
//  VendingMachineCardView.swift
//  VendingMachineLocator
//
//  Created by Claude on 2025/01/23.
//

import SwiftUI
import CoreLocation

/// 自動販売機の情報を表示するカードビュー
struct VendingMachineCardView: View {
    let vendingMachine: VendingMachine
    let currentLocation: CLLocation?
    let onDelete: ((VendingMachine) -> Void)?
    @State private var showingDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // 機種アイコンと稼働状況
                HStack(spacing: 8) {
                    Image(systemName: vendingMachine.machineType.icon)
                        .font(.title3)
                        .foregroundColor(vendingMachine.operatingStatus == .operating ? 
                                       vendingMachine.machineType.color : vendingMachine.operatingStatus.color)
                    
                    // 稼働状況インジケーター
                    Circle()
                        .fill(vendingMachine.operatingStatus.color)
                        .frame(width: 8, height: 8)
                }
                
                Spacer()
                
                // 機種名
                Text(vendingMachine.machineType.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(vendingMachine.machineType.color.opacity(0.2))
                    .clipShape(Capsule())
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(vendingMachine.description)
                    .font(.headline)
                    .lineLimit(2)
                
                // 距離情報
                if let distance = calculateDistance() {
                    Text(distance)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 稼働状況
                Text(vendingMachine.operatingStatus.rawValue)
                    .font(.caption)
                    .foregroundColor(vendingMachine.operatingStatus.color)
                    .fontWeight(.medium)
            }
            
            // 支払い方法
            if !vendingMachine.paymentMethods.isEmpty {
                HStack(spacing: 8) {
                    Text("支払い:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 6) {
                        ForEach(vendingMachine.paymentMethods.prefix(3), id: \.self) { method in
                            Image(systemName: method.icon)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        if vendingMachine.paymentMethods.count > 3 {
                            Text("+\(vendingMachine.paymentMethods.count - 3)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.background)
                .stroke(.quaternary, lineWidth: 1)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .onTapGesture {
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            VendingMachineDetailView(
                vendingMachine: vendingMachine, 
                currentLocation: currentLocation,
                onDelete: onDelete
            )
        }
    }
    
    private func calculateDistance() -> String? {
        guard let currentLocation = currentLocation else { return nil }
        
        let vendingMachineLocation = CLLocation(
            latitude: vendingMachine.latitude,
            longitude: vendingMachine.longitude
        )
        
        let distance = currentLocation.distance(from: vendingMachineLocation)
        
        if distance >= 500 {
            let distanceInKm = distance / 1000
            return "現在地から\(String(format: "%.1f", distanceInKm))キロメートル"
        } else {
            return "現在地から\(Int(distance))メートル"
        }
    }
}

#Preview {
    VendingMachineCardView(
        vendingMachine: VendingMachine(
            id: "1",
            latitude: 35.6895,
            longitude: 139.6917,
            description: "サンプル自動販売機",
            machineType: .beverage,
            operatingStatus: .operating,
            paymentMethods: [.cash, .electronicMoney, .card]
        ),
        currentLocation: CLLocation(latitude: 35.6895, longitude: 139.6917),
        onDelete: { _ in print("削除テスト") }
    )
    .padding()
}