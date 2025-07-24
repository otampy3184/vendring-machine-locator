//
//  DrawerMenuView.swift
//  VendingMachineLocator
//
//  Created by Claude on 2025/01/23.
//

import SwiftUI

/// サイドメニュー（ドロワー）ビュー
struct DrawerMenuView: View {
    @EnvironmentObject private var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ヘッダー
                HeaderSection()
                
                // メニューアイテム
                ScrollView {
                    VStack(spacing: 0) {
                        if authService.isAuthenticated {
                            AuthenticatedMenuItems()
                        } else {
                            UnauthenticatedMenuItems()
                        }
                        
                        Divider()
                            .padding(.vertical, 16)
                        
                        AppInfoSection()
                    }
                }
                
                Spacer()
                
                // フッター
                FooterSection()
            }
            .navigationTitle("メニュー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Header Section
struct HeaderSection: View {
    @EnvironmentObject private var authService: AuthService
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.grid.2x2.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("自販機まっぷ")
                .font(.title2)
                .fontWeight(.bold)
            
            if let user = authService.user {
                VStack(spacing: 4) {
                    Text("ようこそ、\(user.name)さん")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let email = user.email {
                        Text(email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text("ログインしていません")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal)
        .background(.regularMaterial)
    }
}

// MARK: - Authenticated Menu Items
struct AuthenticatedMenuItems: View {
    @EnvironmentObject private var authService: AuthService
    
    var body: some View {
        VStack(spacing: 0) {
            MenuItemButton(
                icon: "plus.circle",
                title: "自動販売機を追加",
                subtitle: "新しい自動販売機を地図に追加",
                action: {
                    // 追加アクションはメイン画面で処理
                }
            )
            
            MenuItemButton(
                icon: "location",
                title: "現在地に移動",
                subtitle: "現在の位置を地図で表示",
                action: {
                    // 位置移動アクションはメイン画面で処理
                }
            )
            
            MenuItemButton(
                icon: "line.3.horizontal.decrease.circle",
                title: "フィルター設定",
                subtitle: "表示する自動販売機を絞り込み",
                action: {
                    // フィルター設定はメイン画面で処理
                }
            )
            
            Divider()
                .padding(.vertical, 16)
            
            MenuItemButton(
                icon: "rectangle.portrait.and.arrow.right",
                title: "サインアウト",
                subtitle: "アカウントからログアウト",
                action: {
                    Task {
                        await authService.signOut()
                    }
                }
            )
        }
    }
}

// MARK: - Unauthenticated Menu Items
struct UnauthenticatedMenuItems: View {
    @EnvironmentObject private var authService: AuthService
    
    var body: some View {
        VStack(spacing: 0) {
            MenuItemButton(
                icon: "person.circle",
                title: "Googleでサインイン",
                subtitle: "自動販売機の追加にはログインが必要です",
                action: {
                    Task {
                        await authService.signInWithGoogle()
                    }
                }
            )
            
            MenuItemButton(
                icon: "location",
                title: "現在地に移動",
                subtitle: "現在の位置を地図で表示",
                action: {
                    // 位置移動アクションはメイン画面で処理
                }
            )
            
            MenuItemButton(
                icon: "line.3.horizontal.decrease.circle",
                title: "フィルター設定",
                subtitle: "表示する自動販売機を絞り込み",
                action: {
                    // フィルター設定はメイン画面で処理
                }
            )
        }
    }
}

// MARK: - App Info Section
struct AppInfoSection: View {
    @State private var showingDebugView = false
    
    var body: some View {
        VStack(spacing: 0) {
            MenuItemButton(
                icon: "info.circle",
                title: "アプリについて",
                subtitle: "バージョン情報とライセンス",
                action: {
                    // アプリ情報の表示
                }
            )
            
            MenuItemButton(
                icon: "questionmark.circle",
                title: "ヘルプ",
                subtitle: "使い方とよくある質問",
                action: {
                    // ヘルプの表示
                }
            )
            
            MenuItemButton(
                icon: "gear",
                title: "設定",
                subtitle: "アプリの設定と環境設定",
                action: {
                    // 設定画面の表示
                }
            )
            
            // デバッグメニュー（開発用）
            MenuItemButton(
                icon: "wrench.and.screwdriver",
                title: "Firebase Storage デバッグ",
                subtitle: "Storage接続状態の確認とトラブルシューティング",
                action: {
                    showingDebugView = true
                }
            )
        }
        .sheet(isPresented: $showingDebugView) {
            FirebaseStorageDebugView()
        }
    }
}

// MARK: - Footer Section
struct FooterSection: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("© 2024 自販機まっぷ")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Version 1.0.0")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.regularMaterial)
    }
}

// MARK: - Menu Item Button
struct MenuItemButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
        .background(.clear)
        .contentShape(Rectangle())
    }
}

#Preview {
    DrawerMenuView()
        .environmentObject(AuthService.shared)
}