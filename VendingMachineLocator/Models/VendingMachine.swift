//
//  VendingMachine.swift
//  VendingMachineLocator
//
//  Created by Claude on 2025/01/23.
//

import Foundation
import CoreLocation
import SwiftUI

/// 自動販売機の機種を表す列挙型
enum MachineType: String, CaseIterable, Codable {
    case beverage = "飲料"
    case food = "食品"
    case ice = "アイス"
    case tobacco = "たばこ"
    case other = "その他"
    
    var icon: String {
        switch self {
        case .beverage: return "cup.and.saucer.fill"
        case .food: return "fork.knife"
        case .ice: return "snowflake"
        case .tobacco: return "smoke.fill"
        case .other: return "questionmark.square"
        }
    }
    
    var color: Color {
        switch self {
        case .beverage: return .blue
        case .food: return .orange
        case .ice: return .cyan
        case .tobacco: return .brown
        case .other: return .gray
        }
    }
}

/// 自動販売機の稼働状況を表す列挙型
enum OperatingStatus: String, CaseIterable, Codable {
    case operating = "営業中"
    case outOfOrder = "故障中"
    case maintenance = "メンテナンス中"
    
    var color: Color {
        switch self {
        case .operating: return .green
        case .outOfOrder: return .red
        case .maintenance: return .yellow
        }
    }
}

/// 支払い方法を表す列挙型
enum PaymentMethod: String, CaseIterable, Codable {
    case cash = "現金"
    case card = "カード"
    case electronicMoney = "電子マネー"
    case qrCode = "QRコード"
    
    var icon: String {
        switch self {
        case .cash: return "yensign.circle"
        case .card: return "creditcard"
        case .electronicMoney: return "wave.3.right.circle"
        case .qrCode: return "qrcode"
        }
    }
}

/// 自動販売機の情報を表すデータモデル
struct VendingMachine: Identifiable, Codable, Equatable {
    var id: String
    let latitude: Double
    let longitude: Double
    let description: String
    let machineType: MachineType
    let operatingStatus: OperatingStatus
    let paymentMethods: [PaymentMethod]
    let lastUpdated: Date
    
    // MARK: - 画像関連フィールド
    let imageURL: String?           // Firebase Storage画像URL
    let thumbnailURL: String?       // サムネイル画像URL
    let hasImage: Bool             // 画像有無フラグ
    let imageUploadedAt: Date?     // 画像アップロード日時
    
    init(id: String = UUID().uuidString, 
         latitude: Double, 
         longitude: Double, 
         description: String,
         machineType: MachineType = .beverage,
         operatingStatus: OperatingStatus = .operating,
         paymentMethods: [PaymentMethod] = [.cash],
         lastUpdated: Date = Date(),
         imageURL: String? = nil,
         thumbnailURL: String? = nil,
         hasImage: Bool = false,
         imageUploadedAt: Date? = nil) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.description = description
        self.machineType = machineType
        self.operatingStatus = operatingStatus
        self.paymentMethods = paymentMethods
        self.lastUpdated = lastUpdated
        self.imageURL = imageURL
        self.thumbnailURL = thumbnailURL
        self.hasImage = hasImage
        self.imageUploadedAt = imageUploadedAt
    }
    
    // MARK: - Firestore compatibility
    private enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case description
        case machineType
        case operatingStatus
        case paymentMethods
        case lastUpdated
        // 画像関連フィールド
        case imageURL
        case thumbnailURL
        case hasImage
        case imageUploadedAt
        // Note: id is handled separately in FirestoreService
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID().uuidString // Will be overwritten by FirestoreService
        self.latitude = try container.decode(Double.self, forKey: .latitude)
        self.longitude = try container.decode(Double.self, forKey: .longitude)
        self.description = try container.decode(String.self, forKey: .description)
        self.machineType = try container.decodeIfPresent(MachineType.self, forKey: .machineType) ?? .beverage
        self.operatingStatus = try container.decodeIfPresent(OperatingStatus.self, forKey: .operatingStatus) ?? .operating
        self.paymentMethods = try container.decodeIfPresent([PaymentMethod].self, forKey: .paymentMethods) ?? [.cash]
        self.lastUpdated = try container.decodeIfPresent(Date.self, forKey: .lastUpdated) ?? Date()
        
        // 画像関連フィールド（新規追加分は既存データとの互換性を保つためOptional）
        self.imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        self.thumbnailURL = try container.decodeIfPresent(String.self, forKey: .thumbnailURL)
        self.hasImage = try container.decodeIfPresent(Bool.self, forKey: .hasImage) ?? false
        self.imageUploadedAt = try container.decodeIfPresent(Date.self, forKey: .imageUploadedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(description, forKey: .description)
        try container.encode(machineType, forKey: .machineType)
        try container.encode(operatingStatus, forKey: .operatingStatus)
        try container.encode(paymentMethods, forKey: .paymentMethods)
        try container.encode(lastUpdated, forKey: .lastUpdated)
        
        // 画像関連フィールド
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encodeIfPresent(thumbnailURL, forKey: .thumbnailURL)
        try container.encode(hasImage, forKey: .hasImage)
        try container.encodeIfPresent(imageUploadedAt, forKey: .imageUploadedAt)
    }
    
    /// 座標からCLLocationCoordinate2Dを生成
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// CLLocationを生成
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Preview用のサンプルデータ
extension VendingMachine {
    static let sampleData: [VendingMachine] = [
        VendingMachine(
            latitude: 35.6895, 
            longitude: 139.6917, 
            description: "渋谷駅前の自動販売機",
            machineType: .beverage,
            operatingStatus: .operating,
            paymentMethods: [.cash, .electronicMoney]
        ),
        VendingMachine(
            latitude: 35.6762, 
            longitude: 139.6503, 
            description: "表参道駅近くの自動販売機",
            machineType: .food,
            operatingStatus: .operating,
            paymentMethods: [.cash, .card, .electronicMoney]
        ),
        VendingMachine(
            latitude: 35.7058, 
            longitude: 139.7736, 
            description: "上野公園の自動販売機",
            machineType: .ice,
            operatingStatus: .maintenance,
            paymentMethods: [.cash]
        )
    ]
}