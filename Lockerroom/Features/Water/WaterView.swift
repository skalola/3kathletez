//
//  WaterView.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/9/25.
//

import SwiftUI

// This file is now used just to display the current goal status
struct WaterView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.blue.opacity(0.8).ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                    
                    Text("Hydration Goal Status")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    
                    
                }
            }
            .navigationTitle("Water Status")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
