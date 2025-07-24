//
//  VendingMachineMapViewModel.swift
//  VendingMachineLocator
//
//  Created by Claude on 2025/01/23.
//

import Foundation
import MapKit
import CoreLocation
import Combine
import UIKit

/// 自動販売機地図画面のビューモデル
@MainActor
class VendingMachineMapViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var mapRegion = MKCoordinateRegion(
        center: LocationService.tokyoCenter,
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @Published var showingAddMachineDialog = false
    @Published var selectedCoordinate: CLLocationCoordinate2D?
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    // MARK: - 画像関連Properties
    @Published var selectedImage: UIImage?
    @Published var imageUploadProgress: Double = 0
    @Published var isUploadingImage = false
    
    // MARK: - Filter Properties
    @Published var selectedMachineTypeFilter: MachineType?
    @Published var selectedOperatingStatusFilter: OperatingStatus?
    
    // MARK: - Photo Selection Properties
    @Published var showingPhotoSelection = false
    
    // MARK: - Detail View Properties
    @Published var selectedVendingMachine: VendingMachine?
    @Published var showingVendingMachineDetail = false
    
    // MARK: - Delete Properties
    @Published var isDeletingVendingMachine = false
    @Published var showingDeleteConfirmation = false
    @Published var vendingMachineToDelete: VendingMachine?
    
    // MARK: - Success Celebration Properties
    @Published var showingSuccessPopup = false
    
    // MARK: - Services
    private let firestoreService = VendingMachineFirestoreService.shared
    private let locationService = LocationService.shared
    private let authService = AuthService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        firestoreService.startListening()
    }
    
    /// 現在地に移動
    func moveToCurrentLocation() {
        Task {
            do {
                let location = try await locationService.getCurrentLocation()
                await MainActor.run {
                    mapRegion = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                }
            } catch {
                await MainActor.run {
                    errorMessage = "現在位置の取得に失敗しました: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// 長押しで自動販売機追加ダイアログを表示
    func handleMapLongPress(at coordinate: CLLocationCoordinate2D) {
        guard authService.isAuthenticated else {
            errorMessage = "自動販売機を追加するにはログインが必要です"
            return
        }
        
        selectedCoordinate = coordinate
        showingAddMachineDialog = true
    }
    
    /// 自動販売機を追加（画像の有無で自動分岐）
    func addVendingMachine(
        description: String,
        machineType: MachineType = .beverage,
        operatingStatus: OperatingStatus = .operating,
        paymentMethods: [PaymentMethod] = [.cash]
    ) {
        guard let coordinate = selectedCoordinate else { return }
        
        Task {
            do {
                isLoading = true
                
                if let image = selectedImage {
                    // 画像付きで追加
                    isUploadingImage = true
                    try await firestoreService.addVendingMachineWithImage(
                        coordinate: coordinate,
                        description: description,
                        machineType: machineType,
                        operatingStatus: operatingStatus,
                        paymentMethods: paymentMethods,
                        image: image
                    )
                } else {
                    // 画像なしで追加
                    try await firestoreService.addVendingMachine(
                        coordinate: coordinate,
                        description: description,
                        machineType: machineType,
                        operatingStatus: operatingStatus,
                        paymentMethods: paymentMethods
                    )
                }
                
                await MainActor.run {
                    isLoading = false
                    isUploadingImage = false
                    showingAddMachineDialog = false
                    selectedCoordinate = nil
                    selectedImage = nil
                    // 成功ポップアップを表示
                    showingSuccessPopup = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    isUploadingImage = false
                    errorMessage = "自動販売機の追加に失敗しました: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// 画像付き自動販売機を追加（外部から直接呼び出し用）
    func addVendingMachineWithImage(
        coordinate: CLLocationCoordinate2D,
        description: String,
        machineType: MachineType,
        operatingStatus: OperatingStatus,
        paymentMethods: [PaymentMethod],
        image: UIImage
    ) {
        selectedCoordinate = coordinate
        selectedImage = image
        addVendingMachine(
            description: description,
            machineType: machineType,
            operatingStatus: operatingStatus,
            paymentMethods: paymentMethods
        )
    }
    
    /// 画像を選択（Exif位置情報自動抽出付き）
    func selectImage(_ image: UIImage) {
        selectedImage = image
        
        // Exif位置情報を抽出して座標を自動設定
        do {
            let result = try ImageService.shared.extractDetailedLocationFromImage(image)
            selectedCoordinate = result.coordinate
            
            // マップ領域も更新（精度に応じてズームレベルを調整）
            let span: MKCoordinateSpan
            if let accuracy = result.accuracy {
                // 精度に基づいてズームレベルを調整
                let delta = min(0.05, max(0.001, accuracy / 100000))
                span = MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
            } else {
                // デフォルトのズームレベル
                span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            }
            
            mapRegion = MKCoordinateRegion(center: result.coordinate, span: span)
            
            // 位置情報が取得できた場合のフィードバック
            print("画像から位置情報を取得しました: \(result.coordinate)")
            if let accuracy = result.accuracy {
                print("精度: ±\(accuracy)m")
            }
        } catch let error as ImageService.ExifLocationError {
            // エラーの場合は現在地を使用
            print("Exif位置情報抽出エラー: \(error.localizedDescription)")
            if let location = locationService.currentLocation {
                selectedCoordinate = location.coordinate
            } else {
                // 現在地も取得できない場合はマップの中心を使用
                selectedCoordinate = mapRegion.center
            }
        } catch {
            print("予期しないエラー: \(error)")
            selectedCoordinate = mapRegion.center
        }
    }
    
    /// 選択した画像をクリア
    func clearSelectedImage() {
        selectedImage = nil
    }
    
    /// 写真選択画面を表示
    func showPhotoSelection() {
        guard authService.isAuthenticated else {
            errorMessage = "自動販売機を追加するにはログインが必要です"
            return
        }
        
        showingPhotoSelection = true
    }
    
    /// 写真選択をキャンセル
    func cancelPhotoSelection() {
        showingPhotoSelection = false
        selectedImage = nil
        selectedCoordinate = nil
    }
    
    /// フィルタリングされた自動販売機を取得
    func getFilteredVendingMachines() -> [VendingMachine] {
        var machines = firestoreService.vendingMachines
        
        // 機種でフィルタリング
        if let machineTypeFilter = selectedMachineTypeFilter {
            machines = machines.filter { $0.machineType == machineTypeFilter }
        }
        
        // 稼働状況でフィルタリング
        if let operatingStatusFilter = selectedOperatingStatusFilter {
            machines = machines.filter { $0.operatingStatus == operatingStatusFilter }
        }
        
        return machines
    }
    
    /// 機種フィルターを設定
    func setMachineTypeFilter(_ machineType: MachineType?) {
        selectedMachineTypeFilter = machineType
    }
    
    /// 稼働状況フィルターを設定
    func setOperatingStatusFilter(_ operatingStatus: OperatingStatus?) {
        selectedOperatingStatusFilter = operatingStatus
    }
    
    /// フィルターをクリア
    func clearFilters() {
        selectedMachineTypeFilter = nil
        selectedOperatingStatusFilter = nil
    }
    
    /// エラーメッセージをクリア
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Detail View Methods
    
    /// 自動販売機を選択して詳細画面を表示
    func selectVendingMachine(_ vendingMachine: VendingMachine) {
        selectedVendingMachine = vendingMachine
        showingVendingMachineDetail = true
    }
    
    /// 詳細画面を閉じる
    func closeVendingMachineDetail() {
        showingVendingMachineDetail = false
        selectedVendingMachine = nil
    }
    
    // MARK: - Delete Methods
    
    /// 削除確認ダイアログを表示
    func showDeleteConfirmation(for vendingMachine: VendingMachine) {
        guard authService.isAuthenticated else {
            errorMessage = "自動販売機を削除するにはログインが必要です"
            return
        }
        
        vendingMachineToDelete = vendingMachine
        showingDeleteConfirmation = true
    }
    
    /// 削除確認をキャンセル
    func cancelDelete() {
        showingDeleteConfirmation = false
        vendingMachineToDelete = nil
    }
    
    /// 自動販売機を削除（画像とFirestoreデータの両方）
    func deleteVendingMachine() async {
        guard let vendingMachine = vendingMachineToDelete else { return }
        
        isDeletingVendingMachine = true
        showingDeleteConfirmation = false
        
        do {
            // 1. 画像データを削除（存在する場合）
            if vendingMachine.hasImage {
                do {
                    try await ImageService.shared.deleteImages(for: vendingMachine.id)
                    print("✅ 画像削除成功: \(vendingMachine.id)")
                } catch {
                    print("⚠️ 画像削除失敗（継続）: \(error.localizedDescription)")
                    // 画像削除失敗でもFirestore削除は継続
                }
            }
            
            // 2. Firestoreデータを削除
            try await firestoreService.deleteVendingMachine(id: vendingMachine.id)
            print("✅ Firestore削除成功: \(vendingMachine.id)")
            
            // 3. 詳細画面を閉じる
            await MainActor.run {
                closeVendingMachineDetail()
                vendingMachineToDelete = nil
                isDeletingVendingMachine = false
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "自動販売機の削除に失敗しました: \(error.localizedDescription)"
                isDeletingVendingMachine = false
                vendingMachineToDelete = nil
            }
        }
    }
}