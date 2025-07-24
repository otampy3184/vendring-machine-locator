import SwiftUI
import MapKit
import CoreLocation

// MARK: - Map Bounds Extensions
struct MapBounds {
    let northEast: CLLocationCoordinate2D
    let southWest: CLLocationCoordinate2D
    
    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        return coordinate.latitude >= southWest.latitude &&
               coordinate.latitude <= northEast.latitude &&
               coordinate.longitude >= southWest.longitude &&
               coordinate.longitude <= northEast.longitude
    }
}

extension MKCoordinateRegion {
    var bounds: MapBounds {
        let northEast = CLLocationCoordinate2D(
            latitude: center.latitude + span.latitudeDelta / 2,
            longitude: center.longitude + span.longitudeDelta / 2
        )
        let southWest = CLLocationCoordinate2D(
            latitude: center.latitude - span.latitudeDelta / 2,
            longitude: center.longitude - span.longitudeDelta / 2
        )
        return MapBounds(northEast: northEast, southWest: southWest)
    }
}

/// メイン画面 - 地図と自動販売機リストを表示
struct VendingMachineMapScreenView: View {
    @StateObject private var viewModel = VendingMachineMapViewModel()
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var firestoreService: VendingMachineFirestoreService
    @State private var showingDrawer = false
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: LocationService.tokyoCenter,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    
    // レスポンシブレイアウト計算
    private func layoutRatios(for geometry: GeometryProxy) -> (mapRatio: CGFloat, cardRatio: CGFloat) {
        let screenHeight = geometry.size.height
        let topBarHeight: CGFloat = 60 // トップバーの高さ
        let filterBarHeight: CGFloat = 60 // フィルターバーの高さ
        let availableHeight = screenHeight - topBarHeight - filterBarHeight
        let minCardHeight: CGFloat = 200
        let minMapHeight: CGFloat = 300
        
        // 基本比率 (2:1)
        var mapRatio: CGFloat = 2.0 / 3.0
        var cardRatio: CGFloat = 1.0 / 3.0
        
        // 小画面対応
        if availableHeight < 700 {
            mapRatio = 0.6
            cardRatio = 0.4
        }
        
        // 最小高さ保証
        let calculatedCardHeight = availableHeight * cardRatio
        let calculatedMapHeight = availableHeight * mapRatio
        
        if calculatedCardHeight < minCardHeight {
            cardRatio = minCardHeight / availableHeight
            mapRatio = 1.0 - cardRatio
        } else if calculatedMapHeight < minMapHeight {
            mapRatio = minMapHeight / availableHeight
            cardRatio = 1.0 - mapRatio
        }
        
        return (mapRatio: mapRatio, cardRatio: cardRatio)
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // トップナビゲーションバー
                TopNavigationBar(onDrawerTap: { showingDrawer.toggle() })
                
                // フィルターツールバー
                FilterToolbarView(viewModel: viewModel)
                
                // マップエリア (2/3)
                ZStack {
                    Map(position: $cameraPosition, interactionModes: .all) {
                        // ユーザーの現在位置を表示
                        if let currentLocation = locationService.currentLocation {
                            Annotation("現在地", coordinate: currentLocation.coordinate) {
                                Circle()
                                    .fill(.blue)
                                    .stroke(.white, lineWidth: 2)
                                    .frame(width: 16, height: 16)
                            }
                        }
                        
                        // 自動販売機マーカーを表示
                        ForEach(visibleVendingMachines) { vendingMachine in
                            Annotation(vendingMachine.description, coordinate: vendingMachine.coordinate) {
                                VendingMachineMarker(
                                    machineType: vendingMachine.machineType,
                                    operatingStatus: vendingMachine.operatingStatus,
                                    onTap: {
                                        viewModel.selectVendingMachine(vendingMachine)
                                    }
                                )
                            }
                        }
                    }
                    .onMapCameraChange { context in
                        viewModel.mapRegion = context.region
                    }
                    .onTapGesture {
                        // 簡単なテスト用 - マップの現在の中心位置を使用
                        viewModel.handleMapLongPress(at: viewModel.mapRegion.center)
                    }
                    
                    // 右下のアクションボタン
                    VStack {
                        Spacer()
                        
                        HStack {
                            Spacer()
                            
                            VStack(spacing: 12) {
                                NavigationButton(icon: "location", action: { viewModel.moveToCurrentLocation() })
                                NavigationButton(icon: "camera.fill", action: { viewModel.showPhotoSelection() })
                            }
                            .padding()
                        }
                    }
                }
                .frame(height: (geometry.size.height - 120) * layoutRatios(for: geometry).mapRatio)
                
                // カードエリア
                VendingMachineListSection(
                    vendingMachines: visibleVendingMachines,
                    currentLocation: locationService.currentLocation,
                    onDelete: { vendingMachine in
                        viewModel.showDeleteConfirmation(for: vendingMachine)
                    }
                )
                .frame(height: (geometry.size.height - 120) * layoutRatios(for: geometry).cardRatio)
            }
        }
        .sheet(isPresented: $showingDrawer) {
            DrawerMenuView()
        }
        .sheet(isPresented: $viewModel.showingVendingMachineDetail) {
            if let selectedVendingMachine = viewModel.selectedVendingMachine {
                VendingMachineDetailView(
                    vendingMachine: selectedVendingMachine,
                    currentLocation: locationService.currentLocation,
                    onDelete: { vendingMachine in
                        viewModel.showDeleteConfirmation(for: vendingMachine)
                    }
                )
            }
        }
        .sheet(isPresented: $viewModel.showingAddMachineDialog) {
            AddVendingMachineDialogView(
                coordinate: viewModel.selectedCoordinate ?? LocationService.tokyoCenter,
                onAdd: { description, machineType, operatingStatus, paymentMethods in
                    viewModel.addVendingMachine(
                        description: description,
                        machineType: machineType,
                        operatingStatus: operatingStatus,
                        paymentMethods: paymentMethods
                    )
                },
                onAddWithImage: { coordinate, description, machineType, operatingStatus, paymentMethods, image in
                    viewModel.addVendingMachineWithImage(
                        coordinate: coordinate,
                        description: description,
                        machineType: machineType,
                        operatingStatus: operatingStatus,
                        paymentMethods: paymentMethods,
                        image: image
                    )
                },
                initialImage: viewModel.selectedImage
            )
        }
        .sheet(isPresented: $viewModel.showingPhotoSelection) {
            EnhancedImageSelectionSheet(
                selectedImage: $viewModel.selectedImage,
                onImageSelected: { image in
                    viewModel.selectImage(image)
                    viewModel.showingPhotoSelection = false
                    viewModel.showingAddMachineDialog = true
                },
                onCancel: {
                    viewModel.cancelPhotoSelection()
                }
            )
        }
        .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.clearError() }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .alert("自動販売機の削除", isPresented: $viewModel.showingDeleteConfirmation) {
            Button("削除", role: .destructive) {
                Task {
                    await viewModel.deleteVendingMachine()
                }
            }
            Button("キャンセル", role: .cancel) {
                viewModel.cancelDelete()
            }
        } message: {
            if let vendingMachine = viewModel.vendingMachineToDelete {
                Text("「\(vendingMachine.description)」を削除しますか？\n\nこの操作は取り消せません。画像データも同時に削除されます。")
            }
        }
        .onAppear {
            Task {
                await locationService.requestLocationPermission()
            }
            if let location = locationService.currentLocation {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                )
            }
        }
        .fullScreenCover(isPresented: $viewModel.showingSuccessPopup) {
            VendingMachineAddSuccessView(isPresented: $viewModel.showingSuccessPopup)
                .background(BackgroundBlurView())
        }
    }
    
    // マップ上に表示されている自動販売機を取得
    private var visibleVendingMachines: [VendingMachine] {
        let mapBounds = viewModel.mapRegion.bounds
        
        return viewModel.getFilteredVendingMachines()
            .filter { vendingMachine in
                mapBounds.contains(vendingMachine.coordinate)
            }
            .sorted { lhs, rhs in
                // マップの中心からの距離でソート
                let center = viewModel.mapRegion.center
                let lhsDistance = CLLocation(latitude: lhs.latitude, longitude: lhs.longitude)
                    .distance(from: CLLocation(latitude: center.latitude, longitude: center.longitude))
                let rhsDistance = CLLocation(latitude: rhs.latitude, longitude: rhs.longitude)
                    .distance(from: CLLocation(latitude: center.latitude, longitude: center.longitude))
                return lhsDistance < rhsDistance
            }
    }
}

// MARK: - Custom Views
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

struct VendingMachineMarkerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

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

struct BackgroundBlurView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct VendingMachineListHeader: View {
    let count: Int
    
    var body: some View {
        HStack {
            Text("マップ上の自動販売機")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Text("\(count)件")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.secondary.opacity(0.1))
                .clipShape(Capsule())
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.thickMaterial)
    }
}

struct VendingMachineEmptyState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.grid.2x2.slash")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("マップ上に自動販売機がありません")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.clear)
    }
}

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
    VendingMachineMapScreenView()
        .environmentObject(LocationService.shared)
        .environmentObject(VendingMachineFirestoreService.shared)
}