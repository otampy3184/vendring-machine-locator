//
//  FirebaseStorageChecker.swift
//  VendingMachineLocator
//
//  Created by Claude on 2025/07/23.
//

import Foundation
import FirebaseAuth
import FirebaseStorage
import FirebaseCore

/// Firebase Storage の設定と接続をチェックするユーティリティ
@MainActor
class FirebaseStorageChecker: ObservableObject {
    
    @Published var checkResults: [String] = []
    @Published var isChecking = false
    
    /// Firebase Storage の設定を総合的にチェック
    func performFullCheck() async {
        isChecking = true
        checkResults = []
        
        addResult("🔍 Firebase Storage 設定チェック開始")
        addResult("=====================================")
        
        // 1. Firebase初期化チェック
        checkFirebaseInitialization()
        
        // 2. 認証状態チェック
        checkAuthenticationStatus()
        
        // 3. Storage設定チェック
        checkStorageConfiguration()
        
        // 4. Storage接続テスト
        await testStorageConnection()
        
        // 5. Security Rules テスト（読み取り）
        await testSecurityRules()
        
        addResult("=====================================")
        addResult("✅ チェック完了")
        
        isChecking = false
    }
    
    private func addResult(_ message: String) {
        checkResults.append(message)
        print(message)
    }
    
    private func checkFirebaseInitialization() {
        addResult("")
        addResult("1️⃣ Firebase 初期化チェック")
        
        if let app = FirebaseApp.app() {
            addResult("✅ Firebase アプリが初期化済み")
            addResult("   - App Name: \(app.name)")
            addResult("   - Project ID: \(app.options.projectID ?? "未設定")")
            addResult("   - Bundle ID: \(app.options.bundleID ?? "未設定")")
            addResult("   - Client ID: \(app.options.clientID ?? "未設定")")
        } else {
            addResult("❌ Firebase アプリが初期化されていません")
            return
        }
    }
    
    private func checkAuthenticationStatus() {
        addResult("")
        addResult("2️⃣ 認証状態チェック")
        
        if let currentUser = Auth.auth().currentUser {
            addResult("✅ ユーザーが認証済み")
            addResult("   - User ID: \(currentUser.uid)")
            addResult("   - Email: \(currentUser.email ?? "未設定")")
            addResult("   - Display Name: \(currentUser.displayName ?? "未設定")")
        } else {
            addResult("❌ ユーザーが未認証")
            addResult("   → Google Sign-In を実行してください")
        }
    }
    
    private func checkStorageConfiguration() {
        addResult("")
        addResult("3️⃣ Storage 設定チェック")
        
        let storage = Storage.storage()
        let reference = storage.reference()
        
        addResult("✅ Storage インスタンス作成成功")
        addResult("   - Bucket: \(reference.bucket)")
        addResult("   - Root Path: \(reference.fullPath)")
        
        // GoogleService-Info.plist の確認
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path) {
            addResult("✅ GoogleService-Info.plist 読み込み成功")
            addResult("   - STORAGE_BUCKET: \(plist["STORAGE_BUCKET"] ?? "未設定")")
            addResult("   - PROJECT_ID: \(plist["PROJECT_ID"] ?? "未設定")")
        } else {
            addResult("❌ GoogleService-Info.plist が見つかりません")
        }
    }
    
    private func testStorageConnection() async {
        addResult("")
        addResult("4️⃣ Storage 接続テスト")
        
        let storage = Storage.storage()
        let testRef = storage.reference().child("connection_test.txt")
        
        do {
            // テストファイルの存在確認（エラーが出ても正常）
            let _ = try await testRef.getMetadata()
            addResult("✅ Storage 接続成功（テストファイルが存在）")
        } catch {
            // エラーコードによる判定
            if let storageError = error as NSError? {
                switch storageError.code {
                case StorageErrorCode.objectNotFound.rawValue:
                    addResult("✅ Storage 接続成功（テストファイルが存在しない - 正常）")
                case StorageErrorCode.unauthenticated.rawValue:
                    addResult("❌ Storage 接続失敗: 認証エラー")
                case StorageErrorCode.unauthorized.rawValue:
                    addResult("❌ Storage 接続失敗: 権限エラー")
                default:
                    addResult("⚠️  Storage 接続: 不明なエラー（コード: \(storageError.code)）")
                }
            } else {
                addResult("⚠️  Storage 接続: \(error.localizedDescription)")
            }
        }
    }
    
    private func testSecurityRules() async {
        addResult("")
        addResult("5️⃣ Security Rules テスト")
        
        guard Auth.auth().currentUser != nil else {
            addResult("⚠️  認証が必要なため Security Rules テストをスキップ")
            return
        }
        
        let storage = Storage.storage()
        let testPath = "vending_machines/test_check/test.txt"
        let testRef = storage.reference().child(testPath)
        let testData = "connection test".data(using: .utf8)!
        
        do {
            // テストアップロード
            let _ = try await testRef.putDataAsync(testData)
            addResult("✅ アップロードテスト成功")
            
            // テストダウンロード
            let _ = try await testRef.data(maxSize: 1024)
            addResult("✅ ダウンロードテスト成功")
            
            // テストファイル削除
            try await testRef.delete()
            addResult("✅ 削除テスト成功")
            
        } catch {
            if let storageError = error as NSError? {
                switch storageError.code {
                case StorageErrorCode.unauthenticated.rawValue:
                    addResult("❌ Security Rules テスト失敗: 認証エラー")
                case StorageErrorCode.unauthorized.rawValue:
                    addResult("❌ Security Rules テスト失敗: 権限エラー")
                    addResult("   → Firebase Console で Security Rules を確認してください")
                default:
                    addResult("❌ Security Rules テスト失敗: エラーコード \(storageError.code)")
                }
            } else {
                addResult("❌ Security Rules テスト失敗: \(error.localizedDescription)")
            }
        }
    }
    
    /// 簡易版チェック（認証とStorage基本接続のみ）
    func performQuickCheck() -> String {
        var result = "🔍 簡易チェック結果:\n"
        
        // Firebase初期化
        if FirebaseApp.app() != nil {
            result += "✅ Firebase 初期化 OK\n"
        } else {
            result += "❌ Firebase 未初期化\n"
            return result
        }
        
        // 認証状態
        if Auth.auth().currentUser != nil {
            result += "✅ ユーザー認証 OK\n"
        } else {
            result += "❌ ユーザー未認証\n"
        }
        
        // Storage設定
        let storage = Storage.storage()
        result += "✅ Storage設定 OK (Bucket: \(storage.reference().bucket))\n"
        
        return result
    }
}