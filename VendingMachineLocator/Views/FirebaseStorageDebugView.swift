//
//  FirebaseStorageDebugView.swift
//  VendingMachineLocator
//
//  Created by Claude on 2025/07/23.
//

import SwiftUI

/// Firebase Storage の設定状態をデバッグするビュー
struct FirebaseStorageDebugView: View {
    @StateObject private var checker = FirebaseStorageChecker()
    @EnvironmentObject private var authService: AuthService
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // クイックステータス
                    statusCard
                    
                    // チェック実行ボタン
                    actionButtons
                    
                    // チェック結果表示
                    if !checker.checkResults.isEmpty {
                        resultsSection
                    }
                    
                    // 手動対処の案内
                    manualInstructions
                }
                .padding()
            }
            .navigationTitle("Firebase Storage デバッグ")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("現在の状態")
                    .font(.headline)
                Spacer()
            }
            
            Text(checker.performQuickCheck())
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                Task {
                    await checker.performFullCheck()
                }
            }) {
                HStack {
                    if checker.isChecking {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "magnifyingglass")
                    }
                    Text(checker.isChecking ? "チェック中..." : "完全チェック実行")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(checker.isChecking)
            
            if !authService.isAuthenticated {
                Button(action: {
                    Task {
                        await authService.signInWithGoogle()
                    }
                }) {
                    HStack {
                        Image(systemName: "person.circle")
                        Text("Google でサインイン")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "list.clipboard")
                    .foregroundColor(.green)
                Text("チェック結果")
                    .font(.headline)
                Spacer()
            }
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(checker.checkResults, id: \.self) { result in
                        Text(result)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(colorForResult(result))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 300)
            .background(Color.black.opacity(0.05))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var manualInstructions: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "wrench.and.screwdriver")
                    .foregroundColor(.orange)
                Text("手動セットアップ手順")
                    .font(.headline)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                instructionItem(
                    icon: "1.circle.fill",
                    text: "Firebase Console で Storage を有効化"
                )
                instructionItem(
                    icon: "2.circle.fill", 
                    text: "Security Rules を設定（認証済みユーザーに許可）"
                )
                instructionItem(
                    icon: "3.circle.fill",
                    text: "Bundle ID が Firebase 設定と一致していることを確認"
                )
                instructionItem(
                    icon: "4.circle.fill",
                    text: "アプリでGoogle Sign-In を実行"
                )
            }
            
            Button(action: {
                if let url = URL(string: "https://console.firebase.google.com/project/trash-bin-locator-421808/storage") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "safari")
                    Text("Firebase Console を開く")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func instructionItem(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
    
    private func colorForResult(_ result: String) -> Color {
        if result.contains("✅") {
            return .green
        } else if result.contains("❌") {
            return .red
        } else if result.contains("⚠️") {
            return .orange
        } else if result.contains("🔍") {
            return .blue
        } else {
            return .primary
        }
    }
}

#Preview {
    FirebaseStorageDebugView()
        .environmentObject(AuthService.shared)
}