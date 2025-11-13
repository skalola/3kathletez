//
//  HomeViewModel.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/9/25.
//
import Foundation
import Combine
import SwiftUI // Import SwiftUI for UIImage

class HomeViewModel: ObservableObject {
    
    // --- UI State ---
    @Published var activeSheet: ActiveSheet?
    
    @Published var userName: String = "Athlete"
    @Published var userLevel: Int = 1           // Placeholder
    
    @Published var userImage: UIImage?
    
    // --- Dependencies ---
    let stateManager: AvatarStateManager
    
    private let gameCenterManager = GameCenterManager.shared
    private var cancellables = Set<AnyCancellable>() // For subscribing

    init(stateManager: AvatarStateManager) {
        self.stateManager = stateManager
        
        // Get the initial values from the manager
        self.userName = gameCenterManager.playerName
        self.userImage = gameCenterManager.playerImage
        
        // Subscribe to future name updates
        gameCenterManager.$playerName
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newName in
                self?.userName = newName
            }
            .store(in: &cancellables)
            
        // Subscribe to future image updates
        gameCenterManager.$playerImage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newImage in
                self?.userImage = newImage
            }
            .store(in: &cancellables)
    }
    
    // --- Public Functions for UI ---
    func didTapSleep() { activeSheet = .sleep }
    func didTapWater() { activeSheet = .water }
    func didTapExercise() { activeSheet = .exercise }
    func didTapMindfulness() { activeSheet = .mindfulness }
    
    func didTapProfile() {
        // *** FIX: Call the correct function ***
        // This now opens the Game Center profile settings, as you wanted.
        print("Profile Tapped. Opening Game Center profile.")
        gameCenterManager.showGameCenterProfile()
    }
}

// Defines the sheets that can be presented
enum ActiveSheet: Identifiable {
    case sleep, water, exercise, mindfulness
    
    var id: Self { self }
}
