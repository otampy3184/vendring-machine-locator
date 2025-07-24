//
//  AuthService.swift
//  VendingMachineLocator
//
//  Created by Claude on 2025/01/23.
//

import Foundation
import Combine
import FirebaseAuth
import GoogleSignIn
import FirebaseCore

/// 認証サービス
@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {
        // Firebase Authの状態変化を監視
        Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in
                self?.updateUser(from: firebaseUser)
            }
        }
        
        // 初期状態を設定
        updateUser(from: Auth.auth().currentUser)
    }
    
    /// Google Sign-Inでログイン
    func signInWithGoogle() async {
        guard let windowScene = await getWindowScene() else {
            errorMessage = "ウィンドウが見つかりません"
            return
        }
        
        guard let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Root view controllerが見つかりません"
            return
        }
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Firebaseの設定が不正です"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Google Sign-Inの設定
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config
            
            // Google Sign-Inを実行
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            let googleUser = result.user
            
            guard let idToken = googleUser.idToken?.tokenString else {
                throw AuthError.invalidToken
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: googleUser.accessToken.tokenString
            )
            
            // Firebase Authでサインイン
            try await Auth.auth().signIn(with: credential)
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "ログインに失敗しました: \(error.localizedDescription)"
        }
    }
    
    /// サインアウト
    func signOut() async {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
        } catch {
            errorMessage = "サインアウトに失敗しました: \(error.localizedDescription)"
        }
    }
    
    /// Firebase UserからアプリのUserを更新
    private func updateUser(from firebaseUser: FirebaseAuth.User?) {
        if let firebaseUser = firebaseUser {
            let appUser = User(
                id: firebaseUser.uid,
                email: firebaseUser.email,
                displayName: firebaseUser.displayName,
                photoURL: firebaseUser.photoURL
            )
            user = appUser
            isAuthenticated = true
        } else {
            user = nil
            isAuthenticated = false
        }
    }
    
    /// ウィンドウシーンを取得
    private func getWindowScene() async -> UIWindowScene? {
        return UIApplication.shared.connectedScenes
            .first { $0.activationState == .foregroundActive } as? UIWindowScene
    }
}

// MARK: - AuthError
enum AuthError: Error, LocalizedError {
    case invalidToken
    case userCancelled
    
    var errorDescription: String? {
        switch self {
        case .invalidToken:
            return "無効なトークンです"
        case .userCancelled:
            return "ユーザーがキャンセルしました"
        }
    }
}