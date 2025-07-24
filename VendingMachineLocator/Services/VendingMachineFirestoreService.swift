//
//  VendingMachineFirestoreService.swift
//  VendingMachineLocator
//
//  Created by Claude on 2025/01/23.
//

import Foundation
import Combine
import CoreLocation
import FirebaseFirestore
import FirebaseFirestoreSwift
import UIKit

/// 自動販売機用Firestoreサービス
@MainActor
class VendingMachineFirestoreService: ObservableObject {
    static let shared = VendingMachineFirestoreService()
    
    @Published var vendingMachines: [VendingMachine] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private let collectionName = "vending_machines"
    
    private init() {}
    
    /// 自動販売機データのリアルタイム監視を開始
    func startListening() {
        guard listener == nil else { return }
        
        isLoading = true
        errorMessage = nil
        
        listener = db.collection(collectionName)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] querySnapshot, error in
                Task { @MainActor in
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = "データの取得に失敗しました: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        self?.errorMessage = "ドキュメントがありません"
                        return
                    }
                    
                    self?.vendingMachines = documents.compactMap { document in
                        do {
                            var vendingMachine = try document.data(as: VendingMachine.self)
                            // IDを設定（ドキュメントIDを使用）
                            vendingMachine.id = document.documentID
                            return vendingMachine
                        } catch {
                            print("ドキュメントのパースに失敗: \(error)")
                            return nil
                        }
                    }
                    
                    self?.errorMessage = nil
                }
            }
    }
    
    /// 自動販売機データ監視を停止
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    /// 新しい自動販売機を追加（画像なし）
    func addVendingMachine(
        coordinate: CLLocationCoordinate2D, 
        description: String,
        machineType: MachineType = .beverage,
        operatingStatus: OperatingStatus = .operating,
        paymentMethods: [PaymentMethod] = [.cash]
    ) async throws {
        isLoading = true
        errorMessage = nil
        
        let vendingMachineData: [String: Any] = [
            "latitude": coordinate.latitude,
            "longitude": coordinate.longitude,
            "description": description,
            "machineType": machineType.rawValue,
            "operatingStatus": operatingStatus.rawValue,
            "paymentMethods": paymentMethods.map { $0.rawValue },
            "lastUpdated": FieldValue.serverTimestamp(),
            "timestamp": FieldValue.serverTimestamp(),
            // 画像関連フィールド（デフォルト値）
            "hasImage": false
        ]
        
        do {
            _ = try await db.collection(collectionName).addDocument(data: vendingMachineData)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "自動販売機の追加に失敗しました: \(error.localizedDescription)"
            throw error
        }
    }
    
    /// 新しい自動販売機を追加（画像付き）
    func addVendingMachineWithImage(
        coordinate: CLLocationCoordinate2D,
        description: String,
        machineType: MachineType = .beverage,
        operatingStatus: OperatingStatus = .operating,
        paymentMethods: [PaymentMethod] = [.cash],
        image: UIImage
    ) async throws {
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        do {
            // 1. まず自動販売機データをFirestoreに追加
            let documentRef = try await db.collection(collectionName).addDocument(data: [
                "latitude": coordinate.latitude,
                "longitude": coordinate.longitude,
                "description": description,
                "machineType": machineType.rawValue,
                "operatingStatus": operatingStatus.rawValue,
                "paymentMethods": paymentMethods.map { $0.rawValue },
                "lastUpdated": FieldValue.serverTimestamp(),
                "timestamp": FieldValue.serverTimestamp(),
                "hasImage": false // 初期値：画像アップロード前
            ])
            
            let vendingMachineId = documentRef.documentID
            
            // 2. 画像をFirebase Storageにアップロード
            let imageService = ImageService.shared
            let imageURL = try await imageService.uploadImage(image, vendingMachineId: vendingMachineId)
            let thumbnailURL = try await imageService.uploadThumbnail(image, vendingMachineId: vendingMachineId)
            
            // 3. Firestoreを画像URLで更新
            let updateData: [String: Any] = [
                "hasImage": true,
                "imageURL": imageURL,
                "thumbnailURL": thumbnailURL,
                "imageUploadedAt": FieldValue.serverTimestamp(),
                "lastUpdated": FieldValue.serverTimestamp()
            ]
            try await documentRef.updateData(updateData)
            
        } catch {
            errorMessage = "画像付き自動販売機の追加に失敗しました: \(error.localizedDescription)"
            throw error
        }
    }
    
    /// 指定した範囲内の自動販売機を取得
    func fetchVendingMachinesInRegion(center: CLLocationCoordinate2D, radiusInMeters: Double) async throws -> [VendingMachine] {
        // 簡易版: 全ての自動販売機を返してクライアントサイドでフィルタリング
        return vendingMachines.filter { vendingMachine in
            let distance = CLLocation(latitude: center.latitude, longitude: center.longitude)
                .distance(from: CLLocation(latitude: vendingMachine.latitude, longitude: vendingMachine.longitude))
            return distance <= radiusInMeters
        }
    }
    
    /// 現在位置から近い順にソート
    func sortByDistance(from location: CLLocation) {
        vendingMachines.sort { first, second in
            let firstDistance = CLLocation(latitude: first.latitude, longitude: first.longitude)
                .distance(from: location)
            let secondDistance = CLLocation(latitude: second.latitude, longitude: second.longitude)
                .distance(from: location)
            return firstDistance < secondDistance
        }
    }
    
    /// 機種でフィルタリング
    func filterByMachineType(_ machineType: MachineType?) -> [VendingMachine] {
        if let machineType = machineType {
            return vendingMachines.filter { $0.machineType == machineType }
        }
        return vendingMachines
    }
    
    /// 稼働状況でフィルタリング
    func filterByOperatingStatus(_ operatingStatus: OperatingStatus?) -> [VendingMachine] {
        if let operatingStatus = operatingStatus {
            return vendingMachines.filter { $0.operatingStatus == operatingStatus }
        }
        return vendingMachines
    }
    
    /// 自動販売機を削除（管理者用）
    func deleteVendingMachine(id: String) async throws {
        do {
            try await db.collection(collectionName).document(id).delete()
        } catch {
            errorMessage = "自動販売機の削除に失敗しました: \(error.localizedDescription)"
            throw error
        }
    }
    
    /// 自動販売機の情報を更新
    func updateVendingMachine(
        id: String,
        operatingStatus: OperatingStatus? = nil,
        paymentMethods: [PaymentMethod]? = nil
    ) async throws {
        var updateData: [String: Any] = [
            "lastUpdated": FieldValue.serverTimestamp()
        ]
        
        if let operatingStatus = operatingStatus {
            updateData["operatingStatus"] = operatingStatus.rawValue
        }
        
        if let paymentMethods = paymentMethods {
            updateData["paymentMethods"] = paymentMethods.map { $0.rawValue }
        }
        
        do {
            try await db.collection(collectionName).document(id).updateData(updateData)
        } catch {
            errorMessage = "自動販売機の更新に失敗しました: \(error.localizedDescription)"
            throw error
        }
    }
}