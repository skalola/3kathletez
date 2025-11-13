//
//  StarryNightView.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/9/25.
//

import SwiftUI
import Combine

struct StarryNightView: View {
    @State private var stars: [Star] = []
    
    struct Star: Identifiable {
        let id = UUID()
        let position: CGPoint
        let size: CGFloat
        let opacity: Double
    }
    
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color.indigo.opacity(0.7)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Stars
                ForEach(stars) { star in
                    Circle()
                        .fill(Color.white.opacity(star.opacity))
                        .frame(width: star.size, height: star.size)
                        .position(star.position)
                        .shadow(color: .white, radius: star.size)
                }
            }
            .onAppear {
                // Create initial stars
                for _ in 0..<100 {
                    stars.append(createStar(in: geo.size))
                }
            }
            .onReceive(timer) { _ in
                // Move stars
                for i in 0..<stars.count {
                    stars[i] = moveStar(star: stars[i], in: geo.size)
                }
            }
        }
    }
    
    func createStar(in size: CGSize) -> Star {
        Star(
            position: CGPoint(x: CGFloat.random(in: 0...size.width), y: CGFloat.random(in: 0...size.height)),
            size: CGFloat.random(in: 1...3),
            opacity: Double.random(in: 0.2...1.0)
        )
    }
    
    func moveStar(star: Star, in size: CGSize) -> Star {
        var newY = star.position.y - (star.size * 0.2) // Move up slowly
        if newY < 0 { newY = size.height } // Loop to bottom
        
        return Star(
            position: CGPoint(x: star.position.x, y: newY),
            size: star.size,
            opacity: star.opacity
        )
    }
}
