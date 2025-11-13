//
//  AuthenticationViewModel.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/9/25.
//

import Foundation
import GameKit
import Combine

class AuthenticationViewModel: ObservableObject {
    
    // *** NEW: Get the shared manager ***
    private var gameCenterManager = GameCenterManager.shared
    
    // We can keep this to show a loading spinner if we want
    @Published var isAuthenticating = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // We can observe the auth state if we need to
        gameCenterManager.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    self?.isAuthenticating = false
                }
            }
            .store(in: &cancellables)
    }

    /// This function is now much simpler.
    func signInWithGameCenter() {
        isAuthenticating = true
        // Just tell the manager to sign in.
        // The manager will publish the VC, and ContentView will present it.
        gameCenterManager.signIn()
    }
}
