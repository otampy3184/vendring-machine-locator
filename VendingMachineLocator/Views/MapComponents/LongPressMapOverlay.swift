import SwiftUI
import MapKit

/// 長押しジェスチャーオーバーレイ
struct LongPressMapOverlay: View {
    let mapRegion: MKCoordinateRegion
    let onLongPress: (CLLocationCoordinate2D) -> Void
    
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
                Color.clear
                    .contentShape(Rectangle())
                    .allowsHitTesting(false)
                    .overlay(
                        Color.clear
                            .contentShape(Rectangle())
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        handleGestureChanged(value: value, geometry: geometry)
                                    }
                                    .onEnded { _ in
                                        handleGestureEnded()
                                    }
                            )
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
        }
    }
    
    // MARK: - Private Methods
    
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
        
        let latitude = mapRegion.center.latitude + mapRegion.span.latitudeDelta * (0.5 - normalizedY)
        let longitude = mapRegion.center.longitude + mapRegion.span.longitudeDelta * (normalizedX - 0.5)
        
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        // リセット
        cancelAllTimers()
        
        // 自動販売機追加ダイアログを表示
        onLongPress(coordinate)
    }
}