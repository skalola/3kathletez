//
//  MindfulnessView.swift
//  Locker Room
//
//  Created by Shiv Kalola on 11/9/25.
//

import SwiftUI

struct MindfulnessView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @StateObject var viewModel = MindfulnessViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                // Placeholder for Zen Garden Background
                Color.mint.opacity(0.8).ignoresSafeArea()
                
                VStack {
                    Text("Mindfulness Module")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    
                    Text("Zen Garden UI goes here.")
                        .foregroundColor(.white)
                }
            }
            .navigationTitle("Mindfulness")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
