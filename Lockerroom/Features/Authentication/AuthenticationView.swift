//
//  AuthenticationView.swift
//  Locker Room
//
//  Created by Shiv Kalola on 11/9/25.
//

import Foundation
import SwiftUI
// We no longer need AuthenticationServices
// import AuthenticationServices

struct AuthenticationView: View {
    @StateObject private var viewModel = AuthenticationViewModel()
    @StateObject private var homeViewModel = HomeViewModel()

    var body: some View {
        
        if viewModel.isAuthenticated {
            ContentView()
                .environmentObject(homeViewModel)
                .environmentObject(viewModel)
                // When we successfully log in, we tell the HomeViewModel
                // to load the Game Center avatar.
                .onAppear {
                    homeViewModel.loadPlayerAvatar()
                }
        } else {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Image("3kappicon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150)
                        .shadow(radius: 5)
                    
                    Text("Welcome to 3K Sportz")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // --- THIS IS THE NEW BUTTON ---
                    // We replaced SignInWithAppleButton with a normal Button
                    Button(action: {
                        viewModel.signIn()
                    }) {
                        HStack {
                            Image(systemName: "gamecontroller.fill")
                            Text("Sign In with Game Center")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                        .padding(.horizontal, 40)
                    }
                }
            }
        }
    }
}
