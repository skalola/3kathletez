//
//  ActionButtonView.swift
//  Locker Room
//
//  Created by Shiv Kalola on 11/9/25.
//

import Foundation
import SwiftUI

// This is a reusable View for your four main action buttons.
struct ActionButtonView: View {
    let icon: String
    let label: String
    let action: () -> Void // A closure to run when tapped
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.black)
                
                Text(label)
                    .font(.custom("Avenir-Heavy", size: 12)) // System font
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity, minHeight: 70)
            .background(Color.white.opacity(0.9))
            .cornerRadius(15)
            .shadow(radius: 3)
        }
    }
}
