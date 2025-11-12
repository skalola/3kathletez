//
//  LockerroomApp.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/9/25.
//

import SwiftUI

@main
struct LockerroomApp: App {
    
    @Environment(\.scenePhase) private var scenePhase
        
    // Create all our 'global' view models and services
    @StateObject private var authViewModel = AuthenticationViewModel()
    @StateObject private var homeViewModel = HomeViewModel()
    
    // --- **** THIS IS THE FIX **** ---
    // We create the AvatarService singleton here and inject it.
    @StateObject private var avatarService = AvatarService.shared
    // --- **** END FIX **** ---

    var body: some Scene {
        WindowGroup {
            AuthenticationView()
                .environmentObject(authViewModel)
                .environmentObject(homeViewModel)
                .environmentObject(avatarService) // <-- Inject the service
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active && oldPhase != .active {
                homeViewModel.appDidBecomeActive()
            }
        }
    }
}
