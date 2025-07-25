import SwiftUI
import MapKit
import CoreLocation

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
                MapSection(
                    viewModel: viewModel,
                    cameraPosition: $cameraPosition,
                    locationService: locationService,
                    visibleVendingMachines: visibleVendingMachines
                )
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

// MARK: - Map Section
private struct MapSection: View {
    @ObservedObject var viewModel: VendingMachineMapViewModel
    @Binding var cameraPosition: MapCameraPosition
    let locationService: LocationService
    let visibleVendingMachines: [VendingMachine]
    
    @State private var isLongPressing = false
    @State private var longPressLocation: CGPoint? = nil
    @State private var longPressProgress: Double = 0.0
    @State private var longPressTimer: Timer? = nil
    @State private var delayTimer: Timer? = nil
    @State private var initialLocation: CGPoint? = nil
    @State private var isDragging = false
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
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
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            handleGestureChanged(value: value, geometry: geometry)
                        }
                        .onEnded { _ in
                            handleGestureEnded()
                        }
                )
            }
            
            // 長押しエフェクトを表示
            if isLongPressing, let location = longPressLocation {
                LongPressEffectView(
                    location: location,
                    progress: longPressProgress
                )
                .allowsHitTesting(false)
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
    }
    
    // MARK: - Gesture Handlers
    
    private func handleGestureChanged(value: DragGesture.Value, geometry: GeometryProxy) {
        let location = value.location
        let translation = value.translation
        let dragDistance = sqrt(pow(translation.width, 2) + pow(translation.height, 2))
        
        if initialLocation == nil {
            // 初回タッチ
            initialLocation = location
            isDragging = false
            
            // 遅延タイマー開始（0.5秒後に長押し判定開始）
            delayTimer?.invalidate()
            delayTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                if !isDragging && initialLocation != nil {
                    // ドラッグしていなければ長押し開始
                    startLongPressAnimation(at: location, in: geometry)
                }
            }
        } else if dragDistance > 10 {
            // 10ピクセル以上移動したらドラッグと判定
            isDragging = true
            cancelAllTimers()
        }
    }
    
    private func handleGestureEnded() {
        initialLocation = nil
        isDragging = false
        cancelAllTimers()
    }
    
    private func startLongPressAnimation(at location: CGPoint, in geometry: GeometryProxy) {
        isLongPressing = true
        longPressLocation = location
        longPressProgress = 0.0
        
        // タイマーを開始してプログレスを更新（0.5秒で完了）
        longPressTimer?.invalidate()
        longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            longPressProgress += 0.02  // 0.5秒で完了するように調整
            
            if longPressProgress >= 1.0 {
                // 長押し完了
                timer.invalidate()
                completeLongPress(at: location, in: geometry)
            }
        }
    }
    
    private func cancelAllTimers() {
        delayTimer?.invalidate()
        delayTimer = nil
        longPressTimer?.invalidate()
        longPressTimer = nil
        
        withAnimation(.easeOut(duration: 0.2)) {
            isLongPressing = false
            longPressLocation = nil
            longPressProgress = 0.0
        }
    }
    
    private func completeLongPress(at location: CGPoint, in geometry: GeometryProxy) {
        // 振動フィードバック
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // マップ座標に変換
        let mapRect = CGRect(x: 0, y: 0, width: geometry.size.width, height: geometry.size.height)
        let normalizedX = location.x / mapRect.width
        let normalizedY = location.y / mapRect.height
        
        let region = viewModel.mapRegion
        let latitude = region.center.latitude + region.span.latitudeDelta * (0.5 - normalizedY)
        let longitude = region.center.longitude + region.span.longitudeDelta * (normalizedX - 0.5)
        
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        // リセット
        cancelAllTimers()
        
        // 自動販売機追加ダイアログを表示
        viewModel.handleMapLongPress(at: coordinate)
    }
}

#Preview {
    VendingMachineMapScreenView()
        .environmentObject(LocationService.shared)
        .environmentObject(VendingMachineFirestoreService.shared)
}