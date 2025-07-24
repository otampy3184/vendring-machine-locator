//
//  VendingMachineAddSuccessView.swift
//  VendingMachineLocator
//
//  Created by Claude on 2025/01/24.
//

import SwiftUI

/// 自動販売機追加成功時の感謝ポップアップビュー
struct VendingMachineAddSuccessView: View {
    @Binding var isPresented: Bool
    @State private var showContent = false
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            // 背景のオーバーレイ
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    // 背景タップで閉じる
                    dismiss()
                }
            
            // メインコンテンツ
            VStack(spacing: 24) {
                // アイコン
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .scaleEffect(showContent ? 1.0 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showContent)
                
                // タイトル
                Text("ありがとうございます！")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // メッセージ
                Text("自動販売機の情報を追加していただき、\nありがとうございます。\n\nあなたの投稿により、より多くの人が\n便利に自動販売機を見つけることができます。")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                // OKボタン
                Button(action: dismiss) {
                    Text("OK")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(32)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            .frame(maxWidth: 350)
            .scaleEffect(scale)
            .opacity(opacity)
            .animation(.easeOut(duration: 0.3), value: scale)
            .animation(.easeOut(duration: 0.3), value: opacity)
            
            // 紙吹雪エフェクト
            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            withAnimation {
                scale = 1.0
                opacity = 1.0
                showContent = true
            }
            
            // 紙吹雪を少し遅れて表示
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    showConfetti = true
                }
            }
            
            // 振動フィードバック
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
    
    private func dismiss() {
        withAnimation(.easeIn(duration: 0.2)) {
            scale = 0.9
            opacity = 0
            showContent = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isPresented = false
        }
    }
}

#Preview {
    VendingMachineAddSuccessView(isPresented: .constant(true))
}