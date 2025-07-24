//
//  VendingMachineDetailView.swift
//  VendingMachineLocator
//
//  Created by Claude on 2025/01/23.
//

import SwiftUI
import CoreLocation
import MapKit

/// 自動販売機詳細ビュー
struct VendingMachineDetailView: View {
    let vendingMachine: VendingMachine
    let currentLocation: CLLocation?
    let onDelete: ((VendingMachine) -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthService
    @State private var region: MKCoordinateRegion
    
    init(vendingMachine: VendingMachine, currentLocation: CLLocation?, onDelete: ((VendingMachine) -> Void)? = nil) {
        self.vendingMachine = vendingMachine
        self.currentLocation = currentLocation
        self.onDelete = onDelete
        self._region = State(initialValue: MKCoordinateRegion(
            center: vendingMachine.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        ))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 画像表示（ある場合のみ）
                    if vendingMachine.hasImage, let imageURL = vendingMachine.imageURL {
                        ImageSection(imageURL: imageURL, imageUploadedAt: vendingMachine.imageUploadedAt)
                    }
                    
                    // 地図
                    Map(coordinateRegion: $region, annotationItems: [vendingMachine]) { machine in
                        MapAnnotation(coordinate: machine.coordinate) {
                            VendingMachineMarker(
                                machineType: machine.machineType,
                                operatingStatus: machine.operatingStatus,
                                onTap: {} // 詳細画面ではタップ無効
                            )
                        }
                    }
                    .frame(height: 200)
                    .cornerRadius(12)
                    .allowsHitTesting(false)
                    
                    VStack(spacing: 16) {
                        // 基本情報
                        InfoSection(title: "基本情報", icon: "info.circle") {
                            VStack(alignment: .leading, spacing: 8) {
                                InfoRow(label: "説明", value: vendingMachine.description)
                                InfoRow(label: "機種", value: vendingMachine.machineType.rawValue, 
                                       valueColor: vendingMachine.machineType.color)
                                InfoRow(label: "稼働状況", value: vendingMachine.operatingStatus.rawValue, 
                                       valueColor: vendingMachine.operatingStatus.color)
                                
                                if let distance = calculateDistance() {
                                    InfoRow(label: "距離", value: distance)
                                }
                            }
                        }
                        
                        // 支払い方法
                        InfoSection(title: "支払い方法", icon: "creditcard") {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(vendingMachine.paymentMethods, id: \.self) { method in
                                    HStack {
                                        Image(systemName: method.icon)
                                            .foregroundColor(.blue)
                                        Text(method.rawValue)
                                            .font(.subheadline)
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(.blue.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        
                        // 位置情報
                        InfoSection(title: "位置情報", icon: "location") {
                            VStack(alignment: .leading, spacing: 8) {
                                InfoRow(label: "緯度", value: String(format: "%.6f", vendingMachine.latitude))
                                InfoRow(label: "経度", value: String(format: "%.6f", vendingMachine.longitude))
                                InfoRow(label: "最終更新", value: formatDate(vendingMachine.lastUpdated))
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("自動販売機詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 削除ボタン（認証済みユーザーのみ表示）
                if authService.isAuthenticated, let onDelete = onDelete {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            onDelete(vendingMachine)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .accessibilityLabel("自動販売機を削除")
                        .accessibilityHint("この自動販売機を完全に削除します")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
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
            return "\(String(format: "%.1f", distanceInKm))キロメートル"
        } else {
            return "\(Int(distance))メートル"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

struct InfoSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            content
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    let valueColor: Color?
    
    init(label: String, value: String, valueColor: Color? = nil) {
        self.label = label
        self.value = value
        self.valueColor = valueColor
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(valueColor ?? .primary)
        }
    }
}

struct ImageSection: View {
    let imageURL: String
    let imageUploadedAt: Date?
    @State private var showingFullScreenImage = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "photo")
                    .foregroundColor(.blue)
                Text("画像")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                if let uploadDate = imageUploadedAt {
                    Text("撮影日: \(formatDate(uploadDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            AsyncImage(url: URL(string: imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxHeight: 250)
                    .clipped()
                    .cornerRadius(12)
                    .onTapGesture {
                        showingFullScreenImage = true
                    }
            } placeholder: {
                Rectangle()
                    .fill(.gray.opacity(0.2))
                    .frame(height: 250)
                    .cornerRadius(12)
                    .overlay(
                        VStack {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("画像を読み込み中...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                    )
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .fullScreenCover(isPresented: $showingFullScreenImage) {
            FullScreenImageView(imageURL: imageURL)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

struct FullScreenImageView: View {
    let imageURL: String
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    
    var body: some View {
        NavigationView {
            ZoomableScrollView {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView("画像を読み込み中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("画像")
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

struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 3.0
        scrollView.minimumZoomScale = 1.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        
        let hostingController = UIHostingController(rootView: content)
        let hostingView = hostingController.view!
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        hostingView.backgroundColor = .clear
        
        scrollView.addSubview(hostingView)
        
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            hostingView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            hostingView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
        
        context.coordinator.hostingView = hostingView
        
        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var hostingView: UIView?
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return hostingView
        }
    }
}

#Preview {
    VendingMachineDetailView(
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
    .environmentObject(AuthService.shared)
}