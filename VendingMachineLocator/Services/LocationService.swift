//
//  LocationService.swift
//  VendingMachineLocator
//
//  Created by Claude on 2025/01/23.
//

import Foundation
import CoreLocation
import Combine

/// 位置情報サービス
@MainActor
class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocationEnabled = false
    @Published var errorMessage: String?
    
    /// 東京の中心座標（デフォルト位置）
    static let tokyoCenter = CLLocationCoordinate2D(latitude: 35.6895, longitude: 139.6917)
    
    private let locationManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        
        authorizationStatus = locationManager.authorizationStatus
        updateLocationEnabled()
    }
    
    /// 位置情報の使用許可を要求
    func requestLocationPermission() async {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            errorMessage = "位置情報の使用が許可されていません。設定から許可してください。"
        case .authorizedWhenInUse, .authorizedAlways:
            await startLocationUpdates()
        @unknown default:
            break
        }
    }
    
    /// 位置情報の更新を開始
    func startLocationUpdates() async {
        guard isLocationEnabled else {
            Task {
                await requestLocationPermission()
            }
            return
        }
        
        locationManager.startUpdatingLocation()
    }
    
    /// 位置情報の更新を停止
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    /// 現在位置を一度だけ取得
    func getCurrentLocation() async throws -> CLLocation {
        guard isLocationEnabled else {
            throw LocationError.permissionDenied
        }
        
        if let currentLocation = currentLocation {
            return currentLocation
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            locationManager.requestLocation()
        }
    }
    
    /// デフォルト位置を返す
    func getDefaultLocation() -> CLLocation {
        return CLLocation(latitude: Self.tokyoCenter.latitude, longitude: Self.tokyoCenter.longitude)
    }
    
    private func updateLocationEnabled() {
        isLocationEnabled = authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            currentLocation = location
            errorMessage = nil
            
            // 一度だけの位置取得リクエストを完了
            if let continuation = locationContinuation {
                locationContinuation = nil
                continuation.resume(returning: location)
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            errorMessage = "位置情報の取得に失敗しました: \(error.localizedDescription)"
            
            // 一度だけの位置取得リクエストでエラーが発生
            if let continuation = locationContinuation {
                locationContinuation = nil
                continuation.resume(throwing: error)
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            authorizationStatus = status
            updateLocationEnabled()
        }
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            Task { @MainActor in
                await startLocationUpdates()
            }
        case .denied, .restricted:
            Task { @MainActor in
                errorMessage = "位置情報の使用が許可されていません"
            }
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
}

// MARK: - LocationError
enum LocationError: Error, LocalizedError {
    case permissionDenied
    case locationUnavailable
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "位置情報の使用許可が必要です"
        case .locationUnavailable:
            return "位置情報を取得できません"
        }
    }
}