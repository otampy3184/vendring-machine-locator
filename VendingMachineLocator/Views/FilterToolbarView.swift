//
//  FilterToolbarView.swift
//  VendingMachineLocator
//
//  Created by Claude on 2025/01/23.
//

import SwiftUI

/// フィルター用ツールバービュー
struct FilterToolbarView: View {
    @ObservedObject var viewModel: VendingMachineMapViewModel
    @State private var showingFilterSheet = false
    
    var body: some View {
        HStack(spacing: 12) {
            // フィルターボタン
            Button(action: { showingFilterSheet = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    Text("フィルター")
                        .font(.caption)
                    
                    // アクティブフィルター数表示
                    if activeFilterCount > 0 {
                        Text("\(activeFilterCount)")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.red)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.regularMaterial)
                .clipShape(Capsule())
            }
            
            Spacer()
            
            // 機種別クイックフィルターボタン
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MachineType.allCases, id: \.self) { machineType in
                        QuickFilterButton(
                            machineType: machineType,
                            isSelected: viewModel.selectedMachineTypeFilter == machineType,
                            action: {
                                if viewModel.selectedMachineTypeFilter == machineType {
                                    viewModel.setMachineTypeFilter(nil)
                                } else {
                                    viewModel.setMachineTypeFilter(machineType)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.regularMaterial)
        .sheet(isPresented: $showingFilterSheet) {
            FilterSheetView(viewModel: viewModel)
        }
    }
    
    private var activeFilterCount: Int {
        var count = 0
        if viewModel.selectedMachineTypeFilter != nil { count += 1 }
        if viewModel.selectedOperatingStatusFilter != nil { count += 1 }
        return count
    }
}

struct QuickFilterButton: View {
    let machineType: MachineType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: machineType.icon)
                    .font(.caption2)
                Text(machineType.rawValue)
                    .font(.caption2)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isSelected ? machineType.color.opacity(0.3) : .gray.opacity(0.1))
            .foregroundColor(isSelected ? machineType.color : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// フィルター設定シート
struct FilterSheetView: View {
    @ObservedObject var viewModel: VendingMachineMapViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 機種フィルター
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "rectangle.grid.2x2")
                            .foregroundColor(.orange)
                        Text("機種で絞り込み")
                            .font(.headline)
                    }
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(MachineType.allCases, id: \.self) { machineType in
                            FilterOptionButton(
                                title: machineType.rawValue,
                                icon: machineType.icon,
                                color: machineType.color,
                                isSelected: viewModel.selectedMachineTypeFilter == machineType,
                                action: {
                                    if viewModel.selectedMachineTypeFilter == machineType {
                                        viewModel.setMachineTypeFilter(nil)
                                    } else {
                                        viewModel.setMachineTypeFilter(machineType)
                                    }
                                }
                            )
                        }
                    }
                }
                
                Divider()
                
                // 稼働状況フィルター
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "power")
                            .foregroundColor(.green)
                        Text("稼働状況で絞り込み")
                            .font(.headline)
                    }
                    
                    VStack(spacing: 8) {
                        ForEach(OperatingStatus.allCases, id: \.self) { status in
                            FilterOptionButton(
                                title: status.rawValue,
                                icon: "circle.fill",
                                color: status.color,
                                isSelected: viewModel.selectedOperatingStatusFilter == status,
                                action: {
                                    if viewModel.selectedOperatingStatusFilter == status {
                                        viewModel.setOperatingStatusFilter(nil)
                                    } else {
                                        viewModel.setOperatingStatusFilter(status)
                                    }
                                }
                            )
                        }
                    }
                }
                
                Spacer()
                
                // リセットボタン
                Button(action: {
                    viewModel.clearFilters()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("フィルターをリセット")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
            }
            .padding()
            .navigationTitle("フィルター設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FilterOptionButton: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(isSelected ? color : .gray)
                Text(title)
                    .font(.subheadline)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(color)
                }
            }
            .padding()
            .background(isSelected ? color.opacity(0.1) : .gray.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? color : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack {
        FilterToolbarView(viewModel: VendingMachineMapViewModel())
        Spacer()
    }
}