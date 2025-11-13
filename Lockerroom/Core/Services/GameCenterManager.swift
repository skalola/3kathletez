//
//  GameCenterManager.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/13/25.
//

import GameKit
import SwiftUI
import Combine

/// This is a new, app-wide singleton service to manage Game Center authentication
/// and user info, as per your request.
class GameCenterManager: NSObject, GKLocalPlayerListener, ObservableObject {
    
    // MARK: - Shared Instance
    static let shared = GameCenterManager()
    
    // MARK: - Published Properties
    
    /// This holds the LOGIN view (if needed)
    @Published var identifiableAuthViewController: IdentifiableUIViewController?
    
    /// *** NEW: This holds the PROFILE view ***
    @Published var identifiableProfileViewController: IdentifiableUIViewController?
    
    /// Tracks the authentication state
    @Published private(set) var isAuthenticated: Bool = GKLocalPlayer.local.isAuthenticated
    
    /// The property you asked for: holds the player's display name.
    @Published private(set) var playerName: String = "Athlete" // Default placeholder
    
    @Published private(set) var playerImage: UIImage?

    // Enforce singleton
    private override init() {
        super.init()
    }

    // MARK: - Public API

    /// Triggers the Game Center authentication process.
    func signIn() {
        let localPlayer = GKLocalPlayer.local
        
        localPlayer.authenticateHandler = { [weak self] viewController, error in
            guard let self = self else { return }
            
            // Ensure we're on the main thread to update @Published properties
            DispatchQueue.main.async {
                if let vc = viewController {
                    // This is the Apple-provided login screen
                    self.identifiableAuthViewController = IdentifiableUIViewController(viewController: vc)
                    return
                }

                if let error = error {
                    print("GameCenter Error: \(error.localizedDescription)")
                    self.isAuthenticated = false
                    self.playerName = "Athlete"
                    self.playerImage = nil
                    return
                }

                if localPlayer.isAuthenticated {
                    print("GameCenter: Player authenticated.")
                    self.isAuthenticated = true
                    self.playerName = localPlayer.displayName
                    
                    self.loadPlayerPhoto()
                    
                    localPlayer.register(self)
                } else {
                    print("GameCenter: Player not authenticated.")
                    self.isAuthenticated = false
                    self.playerName = "Athlete"
                    self.playerImage = nil
                }
            }
        }
    }
    
    /// *** NEW: This is the function you wanted for the profile tap ***
    /// Presents the native Game Center player profile.
    func showGameCenterProfile() {
        guard isAuthenticated else {
            print("GameCenter: Cannot show profile, user not authenticated.")
            // Optionally, call signIn() here as a fallback
            signIn()
            return
        }
        
        let localPlayer = GKLocalPlayer.local
        let profileVC = GKGameCenterViewController(state: .localPlayerProfile)
        
        // We must set the delegate to get the "Done" button to work
        profileVC.gameCenterDelegate = self
        
        DispatchQueue.main.async {
            self.identifiableProfileViewController = IdentifiableUIViewController(viewController: profileVC)
        }
    }
    
    private func loadPlayerPhoto() {
        GKLocalPlayer.local.loadPhoto(for: .normal) { [weak self] image, error in
            if let image = image {
                DispatchQueue.main.async {
                    self?.playerImage = image
                }
            }
            if let error = error {
                print("GameCenter Error: Failed to load player photo: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - GKLocalPlayerListener Delegate
    
    func player(_ player: GKPlayer, didAccept invite: GKInvite) {
        // Handle invites (if you add multiplayer)
    }
    
    func player(_ player: GKPlayer, didRequestMatchWithRecipients recipientPlayers: [GKPlayer]) {
        // Handle match requests (if you add multiplayer)
    }
}

// *** NEW: Delegate to dismiss the profile view ***
extension GameCenterManager: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        // Dismiss the profile view
        DispatchQueue.main.async {
            self.identifiableProfileViewController = nil
        }
    }
}
