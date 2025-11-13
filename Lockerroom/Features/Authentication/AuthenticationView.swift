//
//  AuthenticationView.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/9/25.
//
import SwiftUI

struct AuthenticationView: View {
    @StateObject private var viewModel = AuthenticationViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        // This is your correct Game Center / Apple Auth UI
        NavigationView {
            VStack(spacing: 20) {
                Text("Welcome to Lockerroom")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Sign in to sync your athlete.")
                    .font(.headline)
                    .foregroundColor(.gray)

                Button(action: {
                    // TODO: Add your Game Center/Auth logic
                    print("Signing in...")
                    // viewModel.signInWithGameCenter()
                    dismiss()
                }) {
                    Text("Sign in with Game Center")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarItems(leading: Button("Later") {
                dismiss()
            })
            .padding(.top, 40)
        }
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        // *** FIX: Removed all Unity mock objects ***
        // This now provides a 100% native preview environment.
        
        // 1. Create mock dependencies
        let mockStateManager = AvatarStateManager(persistenceService: PersistenceService())
        let mockHomeVM = HomeViewModel(stateManager: mockStateManager) // Create VM

        // 2. Create the ContentView (the parent)
        ContentView(viewModel: mockHomeVM) // Pass VM
            .environmentObject(mockStateManager)
            // 3. Present the AuthenticationView as a sheet
            .sheet(isPresented: .constant(true)) {
                AuthenticationView()
            }
    }
}
