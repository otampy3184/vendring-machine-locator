//
//  AddVendingMachineDialogView.swift
//  VendingMachineLocator
//
//  Created by Claude on 2025/01/23.
//

import SwiftUI
import CoreLocation
import UIKit

/// 自動販売機追加ダイアログビュー
struct AddVendingMachineDialogView: View {
    let coordinate: CLLocationCoordinate2D
    let onAdd: (String, MachineType, OperatingStatus, [PaymentMethod]) -> Void
    let onAddWithImage: ((CLLocationCoordinate2D, String, MachineType, OperatingStatus, [PaymentMethod], UIImage) -> Void)?
    let initialImage: UIImage?  // 外部から渡される画像
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var imageService = ImageService.shared
    @StateObject private var visionService = VisionAnalysisService.shared
    @State private var description = ""
    @State private var selectedMachineType: MachineType = .beverage
    @State private var selectedOperatingStatus: OperatingStatus = .operating
    @State private var selectedPaymentMethods: Set<PaymentMethod> = [.cash]
    @FocusState private var isTextFieldFocused: Bool
    
    // 画像関連状態
    @State private var selectedImage: UIImage?
    @State private var showingImageSelection = false
    @State private var coordinateFromImage: CLLocationCoordinate2D?
    @State private var useImageLocation = false
    @State private var exifLocationResult: ImageService.ExifLocationResult?
    @State private var exifLocationError: String?
    
    // Vision解析関連状態
    @State private var analysisResult: VendingMachineAnalysisResult?
    @State private var showingAnalysisResult = false
    @State private var useAIAnalysis = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    AddVendingMachineHeaderSection()
                    AddVendingMachineLocationInfoSection(
                        coordinate: useImageLocation && coordinateFromImage != nil ? coordinateFromImage! : coordinate,
                        exifLocationResult: exifLocationResult,
                        useImageLocation: useImageLocation
                    )
                    AddVendingMachineImageSelectionSection(
                        selectedImage: $selectedImage,
                        showingImageSelection: $showingImageSelection,
                        coordinateFromImage: coordinateFromImage,
                        useImageLocation: $useImageLocation,
                        imageService: imageService,
                        visionService: visionService,
                        analysisResult: $analysisResult,
                        showingAnalysisResult: $showingAnalysisResult,
                        useAIAnalysis: $useAIAnalysis,
                        exifLocationResult: exifLocationResult,
                        exifLocationError: exifLocationError
                    )
                    AddVendingMachineDescriptionSection(description: $description, isTextFieldFocused: $isTextFieldFocused)
                    AddVendingMachineMachineTypeSection(selectedMachineType: $selectedMachineType)
                    AddVendingMachineOperatingStatusSection(selectedOperatingStatus: $selectedOperatingStatus)
                    AddVendingMachinePaymentMethodSection(selectedPaymentMethods: $selectedPaymentMethods)
                    AddVendingMachineActionButtonsSection(onAdd: handleAdd, onCancel: { dismiss() }, isAddDisabled: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedPaymentMethods.isEmpty)
                }
                .padding()
            }
            .navigationTitle("自動販売機を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingImageSelection) {
            EnhancedImageSelectionSheet(
                selectedImage: $selectedImage,
                onImageSelected: { image in
                    selectedImage = image
                    showingImageSelection = false
                },
                onCancel: {
                    showingImageSelection = false
                }
            )
        }
        .onChange(of: selectedImage) { oldValue, newImage in
            if let image = newImage {
                // Exif位置情報を抽出（詳細版）
                do {
                    let result = try imageService.extractDetailedLocationFromImage(image)
                    exifLocationResult = result
                    coordinateFromImage = result.coordinate
                    useImageLocation = true
                    exifLocationError = nil
                } catch let error as ImageService.ExifLocationError {
                    exifLocationResult = nil
                    coordinateFromImage = nil
                    useImageLocation = false
                    exifLocationError = error.localizedDescription
                } catch {
                    exifLocationResult = nil
                    coordinateFromImage = nil
                    useImageLocation = false
                    exifLocationError = "位置情報の抽出中にエラーが発生しました"
                }
                
                // Vision解析を実行（一時的にコメントアウト）
                // TODO: Vision Framework のエラーを修正後、コメントを解除
                /*
                Task {
                    do {
                        let result = try await visionService.analyzeVendingMachine(in: image)
                        await MainActor.run {
                            analysisResult = result
                            showingAnalysisResult = true
                        }
                    } catch {
                        await MainActor.run {
                            print("Vision解析エラー: \(error)")
                        }
                    }
                }
                */
            } else {
                coordinateFromImage = nil
                useImageLocation = false
                exifLocationResult = nil
                exifLocationError = nil
                analysisResult = nil
                showingAnalysisResult = false
                useAIAnalysis = false
            }
        }
        .onChange(of: useAIAnalysis) { oldValue, newValue in
            if newValue, let result = analysisResult {
                // AI解析結果を適用
                selectedMachineType = result.machineType
                selectedOperatingStatus = result.operatingStatus
                selectedPaymentMethods = Set(result.suggestedPaymentMethods)
            }
        }
        .onAppear {
            // 初期画像が渡された場合は設定
            if let initialImage = initialImage {
                selectedImage = initialImage
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
    
    private func handleAdd() {
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDescription.isEmpty, !selectedPaymentMethods.isEmpty else { return }
        
        // 位置情報の決定（画像の位置情報を優先するか、元の座標を使用するか）
        let finalCoordinate = (useImageLocation && coordinateFromImage != nil) ? coordinateFromImage! : coordinate
        
        // 画像がある場合は画像付き追加、ない場合は通常追加
        if let image = selectedImage, let onAddWithImage = onAddWithImage {
            onAddWithImage(finalCoordinate, trimmedDescription, selectedMachineType, selectedOperatingStatus, Array(selectedPaymentMethods), image)
        } else {
            onAdd(trimmedDescription, selectedMachineType, selectedOperatingStatus, Array(selectedPaymentMethods))
        }
        dismiss()
    }
}

// MARK: - Section Views

struct AddVendingMachineHeaderSection: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("新しい自動販売機を追加")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("選択した位置に自動販売機を追加します")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct AddVendingMachineLocationInfoSection: View {
    let coordinate: CLLocationCoordinate2D
    let exifLocationResult: ImageService.ExifLocationResult?
    let useImageLocation: Bool
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "location")
                    .foregroundColor(.blue)
                Text("位置")
                    .font(.headline)
            }
            
            // 現在選択されている位置
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: useImageLocation && exifLocationResult != nil ? "photo" : "mappin")
                        .font(.caption)
                        .foregroundColor(useImageLocation && exifLocationResult != nil ? .green : .blue)
                    Text(useImageLocation && exifLocationResult != nil ? "画像から取得した位置" : "マップで選択した位置")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Text("緯度: \(String(format: "%.6f", coordinate.latitude))")
                Text("経度: \(String(format: "%.6f", coordinate.longitude))")
                
                // Exif追加情報
                if useImageLocation, let result = exifLocationResult {
                    if let accuracy = result.accuracy {
                        Text("精度: ±\(String(format: "%.1f", accuracy))m")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    if let altitude = result.altitude {
                        Text("標高: \(String(format: "%.1f", altitude))m")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    if let timestamp = result.timestamp {
                        Text("撮影日時: \(formatDate(timestamp))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding()
            .background(.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

struct AddVendingMachineImageSelectionSection: View {
    @Binding var selectedImage: UIImage?
    @Binding var showingImageSelection: Bool
    let coordinateFromImage: CLLocationCoordinate2D?
    @Binding var useImageLocation: Bool
    let imageService: ImageService
    let visionService: VisionAnalysisService
    @Binding var analysisResult: VendingMachineAnalysisResult?
    @Binding var showingAnalysisResult: Bool
    @Binding var useAIAnalysis: Bool
    let exifLocationResult: ImageService.ExifLocationResult?
    let exifLocationError: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "camera")
                    .foregroundColor(.purple)
                Text("写真")
                    .font(.headline)
                
                if imageService.isUploading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if let selectedImage = selectedImage {
                VStack(spacing: 8) {
                    AddVendingMachineImagePreviewView(
                        selectedImage: selectedImage,
                        coordinateFromImage: coordinateFromImage,
                        useImageLocation: $useImageLocation,
                        showingImageSelection: $showingImageSelection,
                        analysisResult: analysisResult,
                        showingAnalysisResult: showingAnalysisResult,
                        useAIAnalysis: $useAIAnalysis
                    )
                    
                    // 位置情報エラーメッセージ
                    if let error = exifLocationError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        .padding(8)
                        .background(.orange.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
            } else {
                Button(action: {
                    showingImageSelection = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("写真を追加")
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.purple.opacity(0.1))
                    .foregroundColor(.purple)
                    .cornerRadius(8)
                }
            }
        }
    }
}

struct AddVendingMachineImagePreviewView: View {
    let selectedImage: UIImage
    let coordinateFromImage: CLLocationCoordinate2D?
    @Binding var useImageLocation: Bool
    @Binding var showingImageSelection: Bool
    let analysisResult: VendingMachineAnalysisResult?
    let showingAnalysisResult: Bool
    @Binding var useAIAnalysis: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(uiImage: selectedImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 200)
                .cornerRadius(8)
            
            if coordinateFromImage != nil {
                VStack(spacing: 4) {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.green)
                        Text("画像から位置情報を検出しました")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    Toggle("画像の位置情報を使用", isOn: $useImageLocation)
                        .font(.caption)
                }
                .padding(8)
                .background(.green.opacity(0.1))
                .cornerRadius(6)
            }
            
            // AI解析結果表示（一時的にコメントアウト）
            /*
            if showingAnalysisResult, let result = analysisResult {
                VStack(spacing: 6) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.purple)
                        Text("AI解析結果")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.purple)
                        
                        Spacer()
                        
                        Text("信頼度: \(result.confidenceScores.overallRating)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("機種:")
                            Text(result.machineType.rawValue)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(Int(result.confidenceScores.machineTypeConfidence * 100))%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("状況:")
                            Text(result.operatingStatus.rawValue)
                                .fontWeight(.medium)
                                .foregroundColor(result.operatingStatus.color)
                            Spacer()
                            Text("\(Int(result.confidenceScores.operatingStatusConfidence * 100))%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("支払い:")
                            Text(result.suggestedPaymentMethods.map { $0.rawValue }.joined(separator: ", "))
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(Int(result.confidenceScores.paymentMethodsConfidence * 100))%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .font(.caption)
                    
                    Toggle("AI解析結果を使用", isOn: $useAIAnalysis)
                        .font(.caption)
                        .toggleStyle(SwitchToggleStyle(tint: .purple))
                }
                .padding(8)
                .background(.purple.opacity(0.1))
                .cornerRadius(6)
            }
            */
            
            HStack(spacing: 12) {
                Button("写真を変更") {
                    showingImageSelection = true
                }
                .font(.caption)
                .foregroundColor(.blue)
                
                // 再解析ボタン（一時的にコメントアウト）
                /*
                if showingAnalysisResult {
                    Button("再解析") {
                        // 再解析をトリガー
                        Task {
                            // TODO: 再解析ロジック実装
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.purple)
                }
                */
            }
        }
    }
}

struct AddVendingMachineDescriptionSection: View {
    @Binding var description: String
    @FocusState.Binding var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "text.alignleft")
                    .foregroundColor(.blue)
                Text("説明")
                    .font(.headline)
            }
            
            TextField("自動販売機の説明を入力してください", text: $description)
                .textFieldStyle(.roundedBorder)
                .focused($isTextFieldFocused)
        }
    }
}

struct AddVendingMachineMachineTypeSection: View {
    @Binding var selectedMachineType: MachineType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "rectangle.grid.2x2")
                    .foregroundColor(.orange)
                Text("機種")
                    .font(.headline)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(130)), count: 2), spacing: 4) {
                ForEach(MachineType.allCases, id: \.self) { machineType in
                    AddVendingMachineMachineTypeButton(
                        machineType: machineType,
                        isSelected: selectedMachineType == machineType,
                        action: { selectedMachineType = machineType }
                    )
                }
            }
        }
    }
}

struct AddVendingMachineMachineTypeButton: View {
    let machineType: MachineType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: machineType.icon)
                Text(machineType.rawValue)
                Spacer()
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(width: 130, alignment: .leading)
            .background(isSelected ? machineType.color.opacity(0.3) : .gray.opacity(0.1))
            .foregroundColor(isSelected ? machineType.color : .primary)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AddVendingMachineOperatingStatusSection: View {
    @Binding var selectedOperatingStatus: OperatingStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "power")
                    .foregroundColor(.green)
                Text("稼働状況")
                    .font(.headline)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(130)), count: 2), spacing: 4) {
                ForEach(OperatingStatus.allCases, id: \.self) { status in
                    AddVendingMachineOperatingStatusButton(
                        status: status,
                        isSelected: selectedOperatingStatus == status,
                        action: { selectedOperatingStatus = status }
                    )
                }
            }
        }
    }
}

struct AddVendingMachineOperatingStatusButton: View {
    let status: OperatingStatus
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Circle()
                    .fill(status.color)
                    .frame(width: 8, height: 8)
                Text(status.rawValue)
                Spacer()
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(width: 130, alignment: .leading)
            .background(isSelected ? status.color.opacity(0.3) : .gray.opacity(0.1))
            .foregroundColor(isSelected ? status.color : .primary)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AddVendingMachinePaymentMethodSection: View {
    @Binding var selectedPaymentMethods: Set<PaymentMethod>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "creditcard")
                    .foregroundColor(.purple)
                Text("支払い方法")
                    .font(.headline)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(130)), count: 2), spacing: 4) {
                ForEach(PaymentMethod.allCases, id: \.self) { method in
                    AddVendingMachinePaymentMethodButton(
                        method: method,
                        isSelected: selectedPaymentMethods.contains(method),
                        action: {
                            if selectedPaymentMethods.contains(method) {
                                selectedPaymentMethods.remove(method)
                            } else {
                                selectedPaymentMethods.insert(method)
                            }
                        }
                    )
                }
            }
        }
    }
}

struct AddVendingMachinePaymentMethodButton: View {
    let method: PaymentMethod
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                HStack {
                    Image(systemName: method.icon)
                    Text(method.rawValue)
                    Spacer()
                }
                
                HStack {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .opacity(isSelected ? 1.0 : 0.0)
                }
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(width: 130, alignment: .leading)
            .background(isSelected ? .blue.opacity(0.3) : .gray.opacity(0.1))
            .foregroundColor(isSelected ? .blue : .primary)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AddVendingMachineActionButtonsSection: View {
    let onAdd: () -> Void
    let onCancel: () -> Void
    let isAddDisabled: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: onAdd) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("追加")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isAddDisabled)
            
            Button(action: onCancel) {
                Text("キャンセル")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
            }
        }
    }
}

#Preview {
    AddVendingMachineDialogView(
        coordinate: CLLocationCoordinate2D(latitude: 35.6895, longitude: 139.6917),
        onAdd: { description, machineType, operatingStatus, paymentMethods in
            print("Adding vending machine: \(description), \(machineType.rawValue), \(operatingStatus.rawValue), \(paymentMethods.map { $0.rawValue })")
        },
        onAddWithImage: { coordinate, description, machineType, operatingStatus, paymentMethods, image in
            print("Adding vending machine with image: \(description) at \(coordinate)")
        },
        initialImage: nil
    )
}