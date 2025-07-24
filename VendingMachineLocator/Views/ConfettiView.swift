//
//  ConfettiView.swift
//  VendingMachineLocator
//
//  Created by Claude on 2025/01/24.
//

import SwiftUI
import UIKit

/// 紙吹雪パーティクル
struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var color: Color
    var size: CGFloat
    var rotation: Double
    var velocityX: CGFloat  // 横方向の初速度
    var velocityY: CGFloat  // 縦方向の初速度
    var wobble: CGFloat
    var shapeType: ConfettiShapeType
    var source: ConfettiSource  // 発射源（左下 or 右下）
}

enum ConfettiSource {
    case left
    case right
}

enum ConfettiShapeType: CaseIterable {
    case rectangle
    case circle
    case star
    case triangle
}

/// 紙吹雪エフェクトビュー
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var animationTime: Double = 0
    let particleCount = 80  // 左右それぞれ40個
    let gravity: CGFloat = 500  // 重力加速度
    
    // カラフルな色の配列
    let colors: [Color] = [
        .red, .blue, .yellow, .green, .purple,
        .orange, .pink, .mint, .cyan, .indigo
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 紙吹雪パーティクル
                ForEach(particles) { particle in
                    ConfettiParticleView(particle: particle, isAnimating: true)
                        .position(
                            x: calculateX(particle: particle, time: animationTime),
                            y: calculateY(particle: particle, time: animationTime, screenHeight: geometry.size.height)
                        )
                        .opacity(animationTime > 3 ? 0 : (animationTime > 2.5 ? (3 - animationTime) * 2 : 1))
                        .rotationEffect(.degrees(particle.rotation + animationTime * 720))
                        .scaleEffect(animationTime < 0.2 ? animationTime * 5 : 1)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                startAnimation()
            }
        }
        .allowsHitTesting(false)
    }
    
    private func createParticles(in size: CGSize) {
        particles = (0..<particleCount).map { index in
            let isLeftSide = index < particleCount / 2
            let source: ConfettiSource = isLeftSide ? .left : .right
            
            // 発射位置（画面の左下または右下）
            let startX = isLeftSide ? -20 : size.width + 20  // 画面外から発射
            let startY = size.height - 100
            
            // 発射角度と速度をランダムに設定
            let angle = isLeftSide ? 
                Double.random(in: 45...90) :  // 左側: 45度～90度
                Double.random(in: 90...135)    // 右側: 90度～135度
            let speed = CGFloat.random(in: 400...600)
            
            // 角度から速度ベクトルを計算
            let velocityX = speed * CGFloat(cos(angle * .pi / 180))
            let velocityY = -speed * CGFloat(sin(angle * .pi / 180))  // 上向きなので負の値
            
            return ConfettiParticle(
                x: startX,
                y: startY,
                color: colors.randomElement()!,
                size: CGFloat.random(in: 8...16),
                rotation: Double.random(in: 0...360),
                velocityX: velocityX,
                velocityY: velocityY,
                wobble: Double.random(in: 0...2 * .pi),
                shapeType: ConfettiShapeType.allCases.randomElement()!,
                source: source
            )
        }
    }
    
    // X座標の計算（横方向の等速運動 + 揺れ）
    private func calculateX(particle: ConfettiParticle, time: Double) -> CGFloat {
        let baseX = particle.x + particle.velocityX * CGFloat(time)
        let wobble = sin(particle.wobble + time * 3) * 20
        return baseX + wobble
    }
    
    // Y座標の計算（放物線運動）
    private func calculateY(particle: ConfettiParticle, time: Double, screenHeight: CGFloat) -> CGFloat {
        let t = CGFloat(time)
        let y = particle.y + particle.velocityY * t + 0.5 * gravity * t * t
        return min(y, screenHeight + 100)  // 画面外に出すぎないように制限
    }
    
    private func startAnimation() {
        // クラッカー発射時の振動フィードバック
        let impactFeedback = UIImpactFeedbackGenerator(style: .rigid)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        
        // タイマーでアニメーション時間を更新
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            withAnimation(.linear(duration: 0.016)) {
                animationTime += 0.016
            }
            
            if animationTime > 3.5 {
                timer.invalidate()
            }
        }
    }
}

/// 個々の紙吹雪パーティクルビュー
struct ConfettiParticleView: View {
    let particle: ConfettiParticle
    let isAnimating: Bool
    
    var body: some View {
        Group {
            switch particle.shapeType {
            case .rectangle:
                ConfettiShape()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size * 1.5)
            case .circle:
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
            case .star:
                StarConfettiShape()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
            case .triangle:
                TriangleConfettiShape()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
            }
        }
    }
}

/// 紙吹雪の形状
struct ConfettiShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // 四角形ベースの紙吹雪
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.1))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - rect.height * 0.1))
        path.closeSubpath()
        
        return path
    }
}

/// 星型の紙吹雪
struct StarConfettiShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.5
        let points = 5
        
        for i in 0..<points * 2 {
            let angle = (CGFloat(i) * .pi) / CGFloat(points)
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let x = center.x + cos(angle) * radius
            let y = center.y + sin(angle) * radius
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        return path
    }
}

/// 三角形の紙吹雪
struct TriangleConfettiShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        
        return path
    }
}

#Preview {
    ZStack {
        Color.black
        ConfettiView()
    }
}