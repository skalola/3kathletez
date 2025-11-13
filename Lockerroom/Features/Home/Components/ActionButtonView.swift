//
//  ActionButtonView.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/13/25.
//
import SwiftUI

/// This is the view that holds your four main action buttons.
/// It was missing from ContentView.
struct ActionButtonView: View {
    
    // This view is driven by the HomeViewModel
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        HStack(spacing: 15) {
            // Sleep Button
            Button(action: viewModel.didTapSleep) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            .padding(.leading)
            
            // Water Button
            Button(action: viewModel.didTapWater) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            
            // *** NEW: Your App Icon in the footer ***
            Image("3kappicon")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .opacity(0.7)
            
            // Exercise Button
            Button(action: viewModel.didTapExercise) {
                Image(systemName: "figure.run")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            
            // Mindfulness Button
            Button(action: viewModel.didTapMindfulness) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            .padding(.trailing)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(40)
        .shadow(radius: 10)
        .padding(.bottom, 30)
    }
}
