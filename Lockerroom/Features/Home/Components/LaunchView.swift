//
//  LaunchView.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/13/25.
//

import SwiftUI
// *** FIX: We no longer need AuthenticationServices ***
// import AuthenticationServices

/// This is the new "splash screen" for your app.
/// It shows your logo and handles the initial Game Center sign-in.
struct LaunchView: View {
    
    // This binding is passed from LockerroomApp.swift
    @Binding var isAppReady: Bool
    
    // *** FIX: We ONLY observe Game Center. No authManager. ***
    @ObservedObject private var gameCenterManager = GameCenterManager.shared
    
    // State for loading and errors
    @State private var isLoading: Bool = false
    @State private var errorTitle: String = ""
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    
    var body: some View {
        ZStack {
            // A simple dark background
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Spacer()
                
                // 1. Your App Icon
                Image("3kappicon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .padding(.bottom, 20)
                
                // 2. The explicit Sign-in Button
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.vertical, 12)
                } else {
                    // *** FIX: Reverted to a simple Game Center Button ***
                    Button(action: {
                        self.isLoading = true
                        gameCenterManager.signIn()
                    }) {
                        Text("Sign in with Game Center")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding()
                            .frame(width: 280, height: 45)
                            .background(Color.white)
                            .cornerRadius(22.5)
                    }
                }
                
                Spacer()
                Spacer()
            }
        }
        .task {
            // This handles auto-login if they are ALREADY signed in
            if gameCenterManager.isAuthenticated {
                print("LaunchView: User is already authenticated. Proceeding.")
                proceedToApp()
            } else {
                print("LaunchView: User is not authenticated. Waiting for sign-in tap.")
                
                // Listen for authentication failures
                NotificationCenter.default.addObserver(
                    forName: .gameCenterAuthFailed, // This now catches *only* GC errors
                    object: nil,
                    queue: .main
                ) { notification in
                    self.isLoading = false
                    self.errorTitle = "Login Failed"
                    self.errorMessage = (notification.object as? String) ?? "The operation couldn’t be completed."
                    self.showError = true
                }
            }
        }
        .onChange(of: gameCenterManager.isAuthenticated) { isAuthenticated in
            // When Game Center login is complete, we can finally proceed.
            if isAuthenticated {
                print("LaunchView: Game Center is authenticated! Proceeding to app.")
                proceedToApp()
            }
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text(errorTitle),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    /// Fades out the launch screen
    private func proceedToApp() {
        isLoading = false
        withAnimation(.easeOut(duration: 0.5)) {
            self.isAppReady = true
        }
    }
}

// Notification name
extension Notification.Name {
    // This name is defined in GameCenterManager.swift
    static let gameCenterAuthFailed = Notification.Name("gameCenterAuthFailed")
}

struct LaunchView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchView(isAppReady: .constant(false))
    }
}
