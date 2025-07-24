//
//  ImageService.swift
//  VendingMachineLocator
//
//  Created by Claude on 2025/01/23.
//

import Foundation
import SwiftUI
import Combine
import UIKit
import CoreLocation
import ImageIO
import FirebaseStorage
import FirebaseAuth
import FirebaseCore

/// 画像管理サービス - 写真のアップロード、Exif解析等を処理
@MainActor
class ImageService: ObservableObject {
    static let shared = ImageService()
    
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0
    @Published var errorMessage: String?
    
    private let storage = Storage.storage()
    
    private init() {}
    
    // MARK: - 画像アップロード機能
    
    /// Firebase Storageに画像をアップロード
    /// - Parameters:
    ///   - image: アップロードする画像
    ///   - vendingMachineId: 自動販売機ID
    /// - Returns: アップロードされた画像のダウンロードURL
    func uploadImage(_ image: UIImage, vendingMachineId: String) async throws -> String {
        // 認証状態確認
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = "画像をアップロードするにはログインが必要です"
            throw ImageError.authenticationRequired
        }
        
        // Firebase設定の完全性チェック
        let configValidation = validateFirebaseConfiguration()
        if !configValidation.isValid {
            errorMessage = "Firebase設定エラー: \(configValidation.errorMessage ?? "不明")"
            throw ImageError.configurationError
        }
        
        isUploading = true
        uploadProgress = 0
        errorMessage = nil
        
        defer {
            isUploading = false
            uploadProgress = 0
        }
        
        // 画像データの準備（JPEG圧縮）
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            errorMessage = "画像の圧縮に失敗しました"
            throw ImageError.compressionFailed
        }
        
        // ストレージ参照の作成
        let storageRef = storage.reference()
        let imagePath = "vending_machines/\(vendingMachineId)/image.jpg"
        let imageRef = storageRef.child(imagePath)
        
        do {
            // Firebase Storage設定の詳細確認
            print("🔍 Firebase Storage Debug Info:")
            print("  - User ID: \(currentUser.uid)")
            print("  - User Email: \(currentUser.email ?? "未設定")")
            print("  - Is Email Verified: \(currentUser.isEmailVerified)")
            print("  - Storage Bucket: \(storage.reference().bucket)")
            print("  - Upload Path: \(imagePath)")
            print("  - Image Data Size: \(imageData.count) bytes")
            print("  - Configuration Check: \(configValidation.debugInfo)")
            
            // 画像アップロード実行
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            let _ = try await imageRef.putDataAsync(imageData, metadata: metadata)
            
            // ダウンロードURL取得
            let downloadURL = try await imageRef.downloadURL()
            
            print("✅ Upload successful: \(downloadURL.absoluteString)")
            return downloadURL.absoluteString
        } catch {
            print("❌ Upload failed - Error details:")
            print("  - Error: \(error)")
            print("  - LocalizedDescription: \(error.localizedDescription)")
            
            // Firebase Storage固有のエラーハンドリング
            if let storageError = error as NSError? {
                print("  - Error Code: \(storageError.code)")
                print("  - Error Domain: \(storageError.domain)")
                print("  - User Info: \(storageError.userInfo)")
                
                // 具体的なエラー対処
                switch storageError.code {
                case StorageErrorCode.unauthenticated.rawValue:
                    errorMessage = "認証が必要です。ログインしてください。"
                case StorageErrorCode.unauthorized.rawValue:
                    errorMessage = "このファイルにアクセスする権限がありません。"
                case StorageErrorCode.quotaExceeded.rawValue:
                    errorMessage = "ストレージの容量制限に達しました。"
                case StorageErrorCode.nonMatchingChecksum.rawValue:
                    errorMessage = "ファイルの整合性エラーが発生しました。"
                case StorageErrorCode.retryLimitExceeded.rawValue:
                    errorMessage = "再試行回数の上限に達しました。しばらく後に再度お試しください。"
                case StorageErrorCode.cancelled.rawValue:
                    errorMessage = "アップロードがキャンセルされました。"
                default:
                    errorMessage = "画像のアップロードに失敗しました（エラーコード: \(storageError.code)）"
                }
            } else {
                errorMessage = "画像のアップロードに失敗しました: \(error.localizedDescription)"
            }
            
            throw error
        }
    }
    
    /// サムネイル画像をアップロード
    /// - Parameters:
    ///   - image: 元画像
    ///   - vendingMachineId: 自動販売機ID
    /// - Returns: サムネイル画像のダウンロードURL
    func uploadThumbnail(_ image: UIImage, vendingMachineId: String) async throws -> String {
        // 認証状態確認
        guard let currentUser = Auth.auth().currentUser else {
            throw ImageError.authenticationRequired
        }
        // サムネイルサイズに縮小
        let thumbnailImage = resizeImage(image, targetSize: CGSize(width: 200, height: 200))
        
        guard let thumbnailData = thumbnailImage.jpegData(compressionQuality: 0.7) else {
            throw ImageError.compressionFailed
        }
        
        let storageRef = storage.reference()
        let thumbnailPath = "vending_machines/\(vendingMachineId)/thumbnail.jpg"
        let thumbnailRef = storageRef.child(thumbnailPath)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let _ = try await thumbnailRef.putDataAsync(thumbnailData, metadata: metadata)
        let downloadURL = try await thumbnailRef.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    // MARK: - Exif位置情報抽出
    
    /// Exif位置情報抽出結果
    struct ExifLocationResult {
        let coordinate: CLLocationCoordinate2D
        let accuracy: CLLocationAccuracy?
        let altitude: CLLocationDistance?
        let timestamp: Date?
    }
    
    /// Exif位置情報抽出エラー
    enum ExifLocationError: Error, LocalizedError {
        case noImageData
        case noMetadata
        case noGPSData
        case invalidCoordinates
        case coordinatesOutOfRange
        
        var errorDescription: String? {
            switch self {
            case .noImageData:
                return "画像データを読み込めませんでした"
            case .noMetadata:
                return "画像にメタデータが含まれていません"
            case .noGPSData:
                return "画像に位置情報が含まれていません"
            case .invalidCoordinates:
                return "位置情報の形式が正しくありません"
            case .coordinatesOutOfRange:
                return "位置情報が有効な範囲外です"
            }
        }
    }
    
    /// 画像からExif位置情報を抽出（改善版）
    /// - Parameter image: 位置情報付き画像
    /// - Returns: 位置情報の詳細結果
    /// - Throws: ExifLocationError
    func extractDetailedLocationFromImage(_ image: UIImage) throws -> ExifLocationResult {
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            throw ExifLocationError.noImageData
        }
        
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
              let metadata = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] else {
            throw ExifLocationError.noMetadata
        }
        
        guard let gpsData = metadata[kCGImagePropertyGPSDictionary as String] as? [String: Any] else {
            throw ExifLocationError.noGPSData
        }
        
        // 緯度・経度の取得
        guard let latitude = gpsData[kCGImagePropertyGPSLatitude as String] as? CLLocationDegrees,
              let longitude = gpsData[kCGImagePropertyGPSLongitude as String] as? CLLocationDegrees,
              let latRef = gpsData[kCGImagePropertyGPSLatitudeRef as String] as? String,
              let lonRef = gpsData[kCGImagePropertyGPSLongitudeRef as String] as? String else {
            throw ExifLocationError.invalidCoordinates
        }
        
        // 南緯・西経の場合は負の値に変換
        let finalLatitude = latRef == "S" ? -latitude : latitude
        let finalLongitude = lonRef == "W" ? -longitude : longitude
        
        // 座標の妥当性チェック
        guard finalLatitude >= -90 && finalLatitude <= 90 &&
              finalLongitude >= -180 && finalLongitude <= 180 else {
            throw ExifLocationError.coordinatesOutOfRange
        }
        
        let coordinate = CLLocationCoordinate2D(latitude: finalLatitude, longitude: finalLongitude)
        
        // 精度情報の取得（オプション）
        let accuracy = gpsData[kCGImagePropertyGPSHPositioningError as String] as? CLLocationAccuracy
        
        // 高度情報の取得（オプション）
        var altitude: CLLocationDistance?
        if let altitudeValue = gpsData[kCGImagePropertyGPSAltitude as String] as? CLLocationDistance,
           let altitudeRef = gpsData[kCGImagePropertyGPSAltitudeRef as String] as? Int {
            // 海面下の場合は負の値に変換
            altitude = altitudeRef == 1 ? -altitudeValue : altitudeValue
        }
        
        // タイムスタンプの取得（オプション）
        var timestamp: Date?
        if let dateString = gpsData[kCGImagePropertyGPSDateStamp as String] as? String,
           let timeString = gpsData[kCGImagePropertyGPSTimeStamp as String] as? String {
            // GPS日時フォーマット: "yyyy:MM:dd HH:mm:ss"
            let dateTimeString = "\(dateString) \(timeString)"
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
            formatter.timeZone = TimeZone(identifier: "UTC")
            timestamp = formatter.date(from: dateTimeString)
        }
        
        return ExifLocationResult(
            coordinate: coordinate,
            accuracy: accuracy,
            altitude: altitude,
            timestamp: timestamp
        )
    }
    
    /// 画像からExif位置情報を抽出（互換性保持用）
    /// - Parameter image: 位置情報付き画像
    /// - Returns: 緯度経度情報。位置情報がない場合はnil
    func extractLocationFromImage(_ image: UIImage) -> CLLocationCoordinate2D? {
        do {
            let result = try extractDetailedLocationFromImage(image)
            return result.coordinate
        } catch {
            print("Exif位置情報抽出エラー: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - ユーティリティ機能
    
    /// 画像を指定サイズにリサイズ
    /// - Parameters:
    ///   - image: 元画像
    ///   - targetSize: 目標サイズ
    /// - Returns: リサイズされた画像
    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        // アスペクト比を保持しながらリサイズ
        let newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        let rect = CGRect(origin: .zero, size: newSize)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
    
    /// 画像を削除
    /// - Parameter vendingMachineId: 自動販売機ID
    func deleteImages(for vendingMachineId: String) async throws {
        // 認証状態確認
        guard let currentUser = Auth.auth().currentUser else {
            throw ImageError.authenticationRequired
        }
        let storageRef = storage.reference()
        
        // メイン画像削除
        let imageRef = storageRef.child("vending_machines/\(vendingMachineId)/image.jpg")
        try await imageRef.delete()
        
        // サムネイル削除
        let thumbnailRef = storageRef.child("vending_machines/\(vendingMachineId)/thumbnail.jpg")
        try await thumbnailRef.delete()
    }
    
    // MARK: - Firebase設定検証
    
    /// Firebase設定の完全性をチェック
    /// - Returns: 検証結果
    private func validateFirebaseConfiguration() -> FirebaseConfigValidation {
        var errorMessages: [String] = []
        var debugInfo: [String] = []
        
        print("🔍 Firebase設定検証開始")
        
        // 1. Firebase初期化チェック
        guard let firebaseApp = FirebaseApp.app() else {
            let errorMsg = "Firebaseアプリが初期化されていません"
            print("❌ \(errorMsg)")
            return FirebaseConfigValidation(
                isValid: false,
                errorMessage: errorMsg,
                debugInfo: "Firebase App initialization failed"
            )
        }
        
        print("✅ Firebase App初期化OK: \(firebaseApp.name)")
        debugInfo.append("Firebase App: \(firebaseApp.name)")
        
        // 2. GoogleService-Info.plist存在チェック
        guard let plistPath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") else {
            let errorMsg = "GoogleService-Info.plistファイルが見つかりません"
            print("❌ \(errorMsg)")
            errorMessages.append(errorMsg)
            return FirebaseConfigValidation(
                isValid: false,
                errorMessage: errorMessages.joined(separator: ", "),
                debugInfo: debugInfo.joined(separator: ", ")
            )
        }
        
        print("✅ GoogleService-Info.plistファイル存在確認OK: \(plistPath)")
        
        // 3. plist読み込みチェック
        guard let plistDictionary = NSDictionary(contentsOfFile: plistPath) else {
            let errorMsg = "GoogleService-Info.plistの読み込みに失敗しました"
            print("❌ \(errorMsg)")
            errorMessages.append(errorMsg)
            return FirebaseConfigValidation(
                isValid: false,
                errorMessage: errorMessages.joined(separator: ", "),
                debugInfo: debugInfo.joined(separator: ", ")
            )
        }
        
        print("✅ GoogleService-Info.plist読み込みOK")
        
        // 4. 必須設定項目の詳細チェック
        let requiredConfigurationKeys = ["PROJECT_ID", "STORAGE_BUCKET", "BUNDLE_ID", "CLIENT_ID"]
        for configurationKey in requiredConfigurationKeys {
            if let configurationValue = plistDictionary[configurationKey] as? String, !configurationValue.isEmpty {
                print("✅ \(configurationKey): \(configurationValue)")
                debugInfo.append("\(configurationKey): \(configurationValue)")
            } else {
                let errorMsg = "\(configurationKey)が未設定または空です"
                print("❌ \(errorMsg)")
                errorMessages.append(errorMsg)
            }
        }
        
        // 5. Storage bucket設定の詳細チェック
        if let currentStorageBucket = plistDictionary["STORAGE_BUCKET"] as? String {
            let expectedStorageBucket = "trash-bin-locator-421808.firebasestorage.app"
            if currentStorageBucket != expectedStorageBucket {
                let errorMsg = "Storage bucketが期待値と異なります (期待値: \(expectedStorageBucket), 実際: \(currentStorageBucket))"
                print("❌ \(errorMsg)")
                errorMessages.append(errorMsg)
            } else {
                print("✅ Storage bucket設定OK: \(currentStorageBucket)")
                debugInfo.append("Storage bucket設定OK")
            }
        }
        
        // 6. Bundle ID一致確認
        if let plistBundleId = plistDictionary["BUNDLE_ID"] as? String,
           let actualBundleId = Bundle.main.bundleIdentifier {
            if plistBundleId != actualBundleId {
                let errorMsg = "Bundle IDが一致しません (plist: \(plistBundleId), 実際: \(actualBundleId))"
                print("❌ \(errorMsg)")
                errorMessages.append(errorMsg)
            } else {
                print("✅ Bundle ID一致OK: \(plistBundleId)")
                debugInfo.append("Bundle ID一致OK")
            }
        }
        
        // 7. Storage インスタンス作成テスト
        do {
            let storageInstance = Storage.storage()
            let storageReference = storageInstance.reference()
            print("✅ Storage インスタンス作成OK: bucket=\(storageReference.bucket)")
            debugInfo.append("Storage bucket実際値: \(storageReference.bucket)")
        } catch {
            let errorMsg = "Storage インスタンス作成失敗: \(error.localizedDescription)"
            print("❌ \(errorMsg)")
            errorMessages.append(errorMsg)
        }
        
        let validationResult = FirebaseConfigValidation(
            isValid: errorMessages.isEmpty,
            errorMessage: errorMessages.isEmpty ? nil : errorMessages.joined(separator: ", "),
            debugInfo: debugInfo.joined(separator: ", ")
        )
        
        print("🔍 Firebase設定検証完了: \(validationResult.isValid ? "成功" : "失敗")")
        if let errorMsg = validationResult.errorMessage {
            print("❌ エラー詳細: \(errorMsg)")
        }
        
        return validationResult
    }
}

// MARK: - エラー定義

enum ImageError: LocalizedError {
    case compressionFailed
    case uploadFailed
    case invalidImageData
    case noLocationData
    case authenticationRequired
    case configurationError
    
    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "画像の圧縮に失敗しました"
        case .uploadFailed:
            return "画像のアップロードに失敗しました"
        case .invalidImageData:
            return "無効な画像データです"
        case .noLocationData:
            return "画像に位置情報が含まれていません"
        case .authenticationRequired:
            return "画像をアップロードするにはログインが必要です"
        case .configurationError:
            return "Firebase設定に問題があります"
        }
    }
}

// MARK: - Firebase設定検証結果

struct FirebaseConfigValidation {
    let isValid: Bool
    let errorMessage: String?
    let debugInfo: String
}