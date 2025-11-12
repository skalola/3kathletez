//
//  AuthenticationViewModel.swift
//  Locker Room
//
//  Created by Shiv Kalola on 11/9/25.
//
import Foundation
import Combine
import GameKit
import UIKit // Import UIKit to find the window

class AuthenticationViewModel: ObservableObject {
    
    @Published var isAuthenticated: Bool = false
    
    // This holds a reference to the GameKit login view, if needed
    var gameCenterLoginVC: UIViewController?
    
    init() {
        // Set up the "listener" for GameKit authentication.
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            
            if let vc = viewController {
                // If Game Center needs the user to log in, it provides a
                // view controller. We store it to present on button tap.
                print("GameKit: Login VC received, storing it.")
                DispatchQueue.main.async {
                    self?.gameCenterLoginVC = vc
                }
                return
            }
            
            if GKLocalPlayer.local.isAuthenticated {
                // --- SUCCESS ---
                // The user is logged into Game Center (likely auto-login).
                print("GameKit: Player is authenticated.")
                DispatchQueue.main.async {
                    self?.isAuthenticated = true
                }
            } else if error != nil {
                // --- ERROR ---
                print("GameKit: Error authenticating player: \(error?.localizedDescription ?? "unknown error")")
                DispatchQueue.main.async {
                    self?.isAuthenticated = false
                }
            } else {
                // Player is not authenticated, no error.
                print("GameKit: Player is not authenticated.")
                DispatchQueue.main.async {
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    // --- THIS IS THE FIXED FUNCTION ---
    // This function will be called by our NEW button.
    func signIn() {
        print("Sign In Tapped...")
        
        if let vc = self.gameCenterLoginVC {
            // Case 1: We have a login screen from GameKit, let's show it.
            print("Presenting stored GameKit login VC...")
            presentGameCenterLogin(viewController: vc)
        } else if !GKLocalPlayer.local.isAuthenticated {
            // Case 2: We don't have a login screen, and we're not logged in.
            // This can happen if the auto-login failed silently.
            // We'll set the handler *again* to trigger a new request.
            print("No stored VC, re-triggering authenticateHandler...")
            GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
                if let vc = viewController {
                    print("GameKit: Login VC received on 2nd try, presenting...")
                    self?.presentGameCenterLogin(viewController: vc)
                    return
                }
                
                if GKLocalPlayer.local.isAuthenticated {
                    print("GameKit: Player is authenticated.")
                    DispatchQueue.main.async {
                        self?.isAuthenticated = true
                    }
                } else {
                    print("GameKit: Player is not authenticated.")
                    DispatchQueue.main.async {
                        self?.isAuthenticated = false
                    }
                }
            }
        }
    }
    
    // --- NEW HELPER FUNCTION ---
    private func presentGameCenterLogin(viewController: UIViewController) {
        // This is the standard way to present a VC from a non-View struct.
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            print("Could not find key window's root view controller to present GameKit login.")
            return
        }
        
        // Present the GameKit login view controller
        DispatchQueue.main.async {
            rootViewController.present(viewController, animated: true, completion: nil)
        }
    }
    
    func signOut() {
        // This is a placeholder. Real sign out from GameKit is more complex.
        DispatchQueue.main.async {
            self.isAuthenticated = false
        }
    }
}
