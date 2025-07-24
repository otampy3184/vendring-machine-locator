//
//  VisionAnalysisService.swift
//  VendingMachineLocator
//
//  Created by Claude on 2025/01/23.
//

import Foundation
import SwiftUI
import Vision
import UIKit
import CoreML
import CoreLocation

/// Vision Framework を使用した自動販売機画像解析サービス
@MainActor
class VisionAnalysisService: ObservableObject {
    static let shared = VisionAnalysisService()
    
    // MARK: - Published Properties
    @Published var isAnalyzing = false
    @Published var analysisProgress: Double = 0
    @Published var analysisResults: VendingMachineAnalysisResult?
    @Published var errorMessage: String?
    
    private init() {}
    
    // MARK: - 包括的分析機能
    
    /// 自動販売機の包括的分析を実行
    /// - Parameter image: 解析対象の画像
    /// - Returns: 解析結果
    func analyzeVendingMachine(in image: UIImage) async throws -> VendingMachineAnalysisResult {
        isAnalyzing = true
        analysisProgress = 0
        errorMessage = nil
        
        defer {
            isAnalyzing = false
            analysisProgress = 0
        }
        
        do {
            // Step 1: 自動販売機検出 (30%)
            analysisProgress = 0.1
            let detectionResult = try await detectVendingMachine(in: image)
            analysisProgress = 0.3
            
            // Step 2: 機種分類 (60%)
            let machineType = try await classifyMachineType(in: image)
            analysisProgress = 0.6
            
            // Step 3: 稼働状況判定 (80%)
            let operatingStatus = try await determineOperatingStatus(in: image)
            analysisProgress = 0.8
            
            // Step 4: 支払い方法推測 (90%)
            let paymentMethods = try await suggestPaymentMethods(in: image, machineType: machineType)
            analysisProgress = 0.9
            
            // Step 5: 結果統合 (100%)
            let result = VendingMachineAnalysisResult(
                boundingBox: detectionResult.boundingBox,
                machineType: machineType,
                operatingStatus: operatingStatus,
                suggestedPaymentMethods: paymentMethods,
                confidenceScores: ConfidenceScores(
                    machineTypeConfidence: detectionResult.machineTypeConfidence,
                    operatingStatusConfidence: detectionResult.operatingStatusConfidence,
                    paymentMethodsConfidence: detectionResult.paymentMethodsConfidence,
                    overallConfidence: calculateOverallConfidence(detectionResult)
                )
            )
            
            analysisProgress = 1.0
            analysisResults = result
            return result
            
        } catch {
            errorMessage = "画像解析に失敗しました: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - 個別分析機能
    
    /// 自動販売機検出
    /// - Parameter image: 検出対象の画像
    /// - Returns: 検出結果
    func detectVendingMachine(in image: UIImage) async throws -> VendingMachineDetectionResult {
        return try await withCheckedThrowingContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(throwing: VisionAnalysisError.invalidImage)
                return
            }
            
            // Vision リクエスト作成
            let request = VNDetectRectanglesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRectangleObservation],
                      !observations.isEmpty else {
                    // 矩形が検出されない場合はデフォルト値を返す
                    let result = VendingMachineDetectionResult(
                        boundingBox: nil,
                        machineTypeConfidence: 0.3,
                        operatingStatusConfidence: 0.5,
                        paymentMethodsConfidence: 0.4
                    )
                    continuation.resume(returning: result)
                    return
                }
                
                // 最も信頼度の高い矩形を選択
                let bestObservation = observations.max { $0.confidence < $1.confidence }!
                let boundingBox = bestObservation.boundingBox
                
                let result = VendingMachineDetectionResult(
                    boundingBox: boundingBox,
                    machineTypeConfidence: bestObservation.confidence,
                    operatingStatusConfidence: bestObservation.confidence * 0.8,
                    paymentMethodsConfidence: bestObservation.confidence * 0.6
                )
                
                continuation.resume(returning: result)
            }
            
            // 矩形検出設定
            request.minimumAspectRatio = 0.3  // 自動販売機の縦横比を考慮
            request.maximumAspectRatio = 0.8
            request.minimumSize = 0.1
            request.minimumConfidence = 0.3
            
            // Vision処理実行
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// 機種分類
    /// - Parameter image: 分類対象の画像
    /// - Returns: 推定機種
    func classifyMachineType(in image: UIImage) async throws -> MachineType {
        return try await withCheckedThrowingContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(throwing: VisionAnalysisError.invalidImage)
                return
            }
            
            // 色彩分析による簡易分類
            let request = VNClassifyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                // 色彩とテキスト情報から機種を推測
                let machineType = self.inferMachineTypeFromImage(cgImage)
                continuation.resume(returning: machineType)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// 稼働状況判定
    /// - Parameter image: 判定対象の画像
    /// - Returns: 稼働状況
    func determineOperatingStatus(in image: UIImage) async throws -> OperatingStatus {
        return try await withCheckedThrowingContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(throwing: VisionAnalysisError.invalidImage)
                return
            }
            
            // 明度解析による稼働状況判定
            let request = VNDetectFaceLandmarksRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                // 画像の明度を分析して稼働状況を判定
                let operatingStatus = self.inferOperatingStatusFromBrightness(cgImage)
                continuation.resume(returning: operatingStatus)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// 支払い方法推測
    /// - Parameters:
    ///   - image: 解析対象の画像
    ///   - machineType: 機種情報
    /// - Returns: 推奨支払い方法
    func suggestPaymentMethods(in image: UIImage, machineType: MachineType) async throws -> [PaymentMethod] {
        return try await withCheckedThrowingContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(throwing: VisionAnalysisError.invalidImage)
                return
            }
            
            // テキスト認識による支払い方法検出
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    // デフォルト支払い方法を返す
                    continuation.resume(returning: self.getDefaultPaymentMethods(for: machineType))
                    return
                }
                
                let paymentMethods = self.extractPaymentMethodsFromText(observations, machineType: machineType)
                continuation.resume(returning: paymentMethods)
            }
            
            // 日本語テキスト認識設定
            request.recognitionLanguages = ["ja", "en"]
            request.recognitionLevel = .accurate
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// 画像から機種を推測
    private func inferMachineTypeFromImage(_ cgImage: CGImage) -> MachineType {
        // 画像の色彩分析
        let colors = analyzeImageColors(cgImage)
        
        // 色彩パターンから機種を推測
        if colors.hasBlueAndWhite {
            return .beverage
        } else if colors.hasRedAndYellow {
            return .food
        } else if colors.hasBlackAndWhite {
            return .tobacco
        } else {
            return .beverage // デフォルト
        }
    }
    
    /// 明度から稼働状況を推測
    private func inferOperatingStatusFromBrightness(_ cgImage: CGImage) -> OperatingStatus {
        let brightness = calculateImageBrightness(cgImage)
        
        if brightness > 0.6 {
            return .operating
        } else if brightness > 0.3 {
            return .maintenance
        } else {
            return .outOfOrder
        }
    }
    
    /// テキストから支払い方法を抽出
    private func extractPaymentMethodsFromText(_ observations: [VNRecognizedTextObservation], machineType: MachineType) -> [PaymentMethod] {
        var detectedMethods: Set<PaymentMethod> = []
        
        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else { continue }
            let text = topCandidate.string.lowercased()
            
            // 支払い方法キーワード検索
            if text.contains("現金") || text.contains("cash") {
                detectedMethods.insert(.cash)
            }
            if text.contains("カード") || text.contains("card") {
                detectedMethods.insert(.card)
            }
            if text.contains("電子マネー") || text.contains("ic") {
                detectedMethods.insert(.electronicMoney)
            }
            if text.contains("qr") || text.contains("paypay") || text.contains("pay") {
                detectedMethods.insert(.qrCode)
            }
        }
        
        // 検出されなかった場合はデフォルト値
        if detectedMethods.isEmpty {
            return getDefaultPaymentMethods(for: machineType)
        }
        
        return Array(detectedMethods)
    }
    
    /// 機種別デフォルト支払い方法
    private func getDefaultPaymentMethods(for machineType: MachineType) -> [PaymentMethod] {
        switch machineType {
        case .beverage:
            return [.cash, .electronicMoney]
        case .food:
            return [.cash, .card, .electronicMoney]
        case .ice:
            return [.cash]
        case .tobacco:
            return [.cash, .card]
        case .other:
            return [.cash]
        }
    }
    
    /// 全体的な信頼度計算
    private func calculateOverallConfidence(_ detection: VendingMachineDetectionResult) -> Float {
        let weights: [Float] = [0.4, 0.3, 0.3] // 機種、稼働状況、支払い方法の重み
        let scores = [
            detection.machineTypeConfidence,
            detection.operatingStatusConfidence,
            detection.paymentMethodsConfidence
        ]
        
        return zip(weights, scores).reduce(0) { $0 + $1.0 * $1.1 }
    }
    
    /// 画像色彩分析
    private func analyzeImageColors(_ cgImage: CGImage) -> ImageColorAnalysis {
        // 簡易的な色彩分析
        // 実際の実装では、より高度な色彩分析を行う
        return ImageColorAnalysis(
            hasBlueAndWhite: true,  // プレースホルダー
            hasRedAndYellow: false,
            hasBlackAndWhite: false
        )
    }
    
    /// 画像明度計算
    private func calculateImageBrightness(_ cgImage: CGImage) -> Float {
        // 簡易的な明度計算
        // 実際の実装では、ピクセルレベルの明度計算を行う
        return 0.7 // プレースホルダー
    }
}

// MARK: - Data Models

/// 自動販売機分析結果
struct VendingMachineAnalysisResult {
    let boundingBox: CGRect?
    let machineType: MachineType
    let operatingStatus: OperatingStatus
    let suggestedPaymentMethods: [PaymentMethod]
    let confidenceScores: ConfidenceScores
}

/// 信頼度スコア
struct ConfidenceScores {
    let machineTypeConfidence: Float
    let operatingStatusConfidence: Float
    let paymentMethodsConfidence: Float
    let overallConfidence: Float
    
    /// UI表示用の全体評価
    var overallRating: String {
        switch overallConfidence {
        case 0.8...1.0: return "非常に高い"
        case 0.6..<0.8: return "高い"
        case 0.4..<0.6: return "中程度"
        case 0.2..<0.4: return "低い"
        default: return "非常に低い"
        }
    }
}

/// 自動販売機検出結果
struct VendingMachineDetectionResult {
    let boundingBox: CGRect?
    let machineTypeConfidence: Float
    let operatingStatusConfidence: Float
    let paymentMethodsConfidence: Float
}

/// 画像色彩分析結果
struct ImageColorAnalysis {
    let hasBlueAndWhite: Bool
    let hasRedAndYellow: Bool
    let hasBlackAndWhite: Bool
}

// MARK: - Error Types

enum VisionAnalysisError: LocalizedError {
    case invalidImage
    case analysisTimeout
    case insufficientData
    case visionFrameworkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "無効な画像データです"
        case .analysisTimeout:
            return "解析がタイムアウトしました"
        case .insufficientData:
            return "解析に十分なデータがありません"
        case .visionFrameworkError(let error):
            return "Vision解析エラー: \(error.localizedDescription)"
        }
    }
}