//
//  HealthMeterView.swift
//  Locker Room
//
//  Created by Shiv Kalola on 11/9/25.
//

import SwiftUI

// This is a reusable View for your health meters.
struct HealthMeterView: View {
    let label: String // e.g., "MENTAL"
    let value: Double // 0.0 to 1.0
    let color: Color
    
    // Calculates the value as a percentage string (e.g., "75%")
    private var valueText: String {
        "\(Int(value * 100))%"
    }
    
    var body: some View {
        // --- FIX: Change alignment to center and spacing ---
        VStack(alignment: .leading, spacing: 6) {
            
            // 1. VALUE (The actual number)
//            Text(valueText)
//                .font(.headline.bold())
//                .foregroundColor(.white)
            
            // 2. METER BAR
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Meter Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.5))
                    
                    // Meter Foreground
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color)
                        // This scales the bar based on the 'value'
                        .frame(width: max(0, geo.size.width * CGFloat(value)))
                        // Animate changes
                        .animation(.spring(), value: value)
                }
            }
            .frame(height: 12)
            
            // 3. LABEL (Below the bar, in smaller text)
            Text(label)
                .font(.caption.bold())
                .foregroundColor(.white)
        }
    }
}
