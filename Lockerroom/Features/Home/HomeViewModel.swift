//
//  HomeViewModel.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/9/25.
//
//  MODIFIED:
//  - Added Tamagotchi-style game loop.
//  - Added Timer to call gameTick() every 60 seconds.
//  - gameTick() now drains health stats over time.
//  - Added evaluateAvatarState() "brain" to set avatar state based on stats.
//  - User actions (logWater, logMindfulnessSession) now REFILL stats
//    instead of just setting state.
//  - Avatar stats (mentalHealth, physicalHealth) are now loaded from
//    and saved to userProfile, using the PersistenceService.
//

import Foundation
import SwiftUI
import GameKit
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    
    // --- Published Properties for UI ---
    @Published var avatar = Avatar()
    @Published var userProfile: UserProfile
    @Published var playerAvatarImage: Image = Image(systemName: "person.circle.fill")
    @Published var isActionMenuVisible: Bool = false
    @Published var isHydrating: Bool = false
    @Published var hasConfiguredAvatar: Bool = false

    // --- Sheet Presentation ---
    @Published var isShowingSleepView: Bool = false
    @Published var isShowingMindfulnessView: Bool = false
    @Published var isShowingExerciseView: Bool = false
    @Published var isShowingProfileView: Bool = false
    
    // --- Services ---
    private let persistenceService = PersistenceService()
    private let avatarService = AvatarService.shared
    private let notificationManager = NotificationManager.shared // FIX 1: Use the .shared singleton instance
    private var healthUpdateSubscriber: AnyCancellable?
    
    // --- Tamagotchi Game Loop ---
    private var gameTimer: Timer?

    // --- Initialization ---
    init() {
        // 1. Load the saved profile, which now includes health stats
        let loadedProfile = persistenceService.loadProfile()
        self.userProfile = loadedProfile
        
        // 2. Immediately set the avatar state based on loaded stats
        self.evaluateAvatarState()

        // 3. Set up listeners
        self.listenForHealthKitUpdates()
        self.configureAvatar(profile: loadedProfile)
        
        // 4. Start the game loop
        self.startGameLoop()
    }
    
    deinit {
        // Clean up timer
        gameTimer?.invalidate()
    }
    
    // MARK: - Tamagotchi Game Loop
    
    /// Starts the passive state-change timer.
    private func startGameLoop() {
        gameTimer?.invalidate()
        // Fire the gameTick() function every 60 seconds
        gameTimer = Timer.scheduledTimer(
            timeInterval: 60.0, // 1 minute
            target: self,
            selector: #selector(gameTick),
            userInfo: nil,
            repeats: true
        )
        print("Game loop started.")
    }
    
    /// The main "Tamagotchi" loop. Called by the timer.
    /// This passively drains stats over time.
    @objc private func gameTick() {
        print("Game Tick: Draining stats...")
        
        // 1. Degrade stats
        // Physical health drains faster than mental
        userProfile.physicalHealth -= 0.01 // Drains 1% per minute (full drain in ~1.5 hours)
        userProfile.mentalHealth -= 0.005 // Drains 0.5% per minute (full drain in ~3 hours)
        
        // 2. Clamp values (ensure they don't go below 0)
        userProfile.physicalHealth = max(0, userProfile.physicalHealth)
        userProfile.mentalHealth = max(0, userProfile.mentalHealth)
        
        // 3. Re-evaluate the avatar's state based on new stats
        evaluateAvatarState()
        
        // 4. Save the new degraded stats
        persistenceService.saveProfile(userProfile)
    }
    
    /// The "brain" of the Tamagotchi.
    /// Sets the avatar's state and message based on current health stats.
    private func evaluateAvatarState() {
        
        // Don't change state if user is in the middle of an action
        if isHydrating || isShowingExerciseView || isShowingMindfulnessView {
            return
        }

        // --- Priority 1: Check for "Elite" status ---
        if userProfile.physicalHealth > 0.9 && userProfile.mentalHealth > 0.9 {
            avatar.currentState = .elite
            avatar.statusMessage = "In the zone!"
            
        // --- Priority 2: Check for "Sick" or "Sad" states ---
        } else if userProfile.physicalHealth < 0.2 {
            avatar.currentState = .lowEnergy
            avatar.statusMessage = "Feeling drained..."
            
        } else if userProfile.physicalHealth < 0.4 {
            // This is a good proxy for water, as water logs fill physicalHealth
            avatar.currentState = .dehydrated
            avatar.statusMessage = "So thirsty..."
            
        } else if userProfile.mentalHealth < 0.3 {
            avatar.currentState = .sleeping // Using "sleeping" as a "tired/sad" state
            avatar.statusMessage = "Need a break..."
            
        // --- Default: If nothing is wrong, be idle ---
        } else {
            avatar.currentState = .idle
            avatar.statusMessage = "Ready to train!"
        }
        
        print("Avatar state evaluated: \(avatar.currentState)")
    }

    // MARK: - Avatar & Profile Configuration
    
    func configureAvatar(profile: UserProfile) {
        if !profile.avatarURL.isEmpty, let url = URL(string: profile.avatarURL) {
            avatarService.loadAvatar(from: url)
            self.hasConfiguredAvatar = true
        } else {
            self.hasConfiguredAvatar = false
        }
    }

    func loadPlayerAvatar() {
        GKLocalPlayer.local.loadPhoto(for: .normal) { image, error in
            if let image = image {
                self.playerAvatarImage = Image(uiImage: image)
            }
        }
    }
    
    func saveProfile() {
        persistenceService.saveProfile(userProfile)
        // Re-configure avatar in case URL changed
        configureAvatar(profile: userProfile)
    }

    // MARK: - User Actions (Filling the Meters)

    func logWaterAndAnimate() {
        // 1. Refill the stat
        userProfile.physicalHealth += 0.1 // Water gives 10% physical health
        userProfile.physicalHealth = min(1.0, userProfile.physicalHealth) // Clamp at 1.0
        
        // 2. Save the new stat
        saveProfile()

        // 3. Play the animation
        self.isHydrating = true
        self.avatar.currentState = .drinking
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isHydrating = false
            // 4. Re-evaluate state. This will check if drinking fixed the problem.
            self.evaluateAvatarState()
        }
    }
    
    func logAlarmSet() {
        // Setting an alarm boosts mental health slightly
        userProfile.mentalHealth += 0.1
        userProfile.mentalHealth = min(1.0, userProfile.mentalHealth)
        
        self.avatar.currentState = .sleeping
        self.avatar.statusMessage = "Ready for bed."
        
        saveProfile()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.evaluateAvatarState()
        }
    }
    
    func logMindfulnessSession() {
        // This is a big boost to mental health
        userProfile.mentalHealth += 0.4
        userProfile.mentalHealth = min(1.0, userProfile.mentalHealth)
        
        self.avatar.currentState = .mindfulness
        self.avatar.statusMessage = "Feeling calm."
        
        saveProfile()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.evaluateAvatarState()
        }
    }
    
    func logExercise() {
        // This is a big boost to physical health
        userProfile.physicalHealth += 0.3
        userProfile.physicalHealth = min(1.0, userProfile.physicalHealth)
        
        self.avatar.currentState = .exercising
        self.avatar.statusMessage = "Pumped up!"
        
        saveProfile()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.evaluateAvatarState()
        }
    }

    // MARK: - HealthKit Integration

    private func listenForHealthKitUpdates() {
        healthUpdateSubscriber = NotificationCenter.default
            .publisher(for: .didLogHealthKitActivity) // FIX 2: This will now compile
            .compactMap { $0.object as? LoggedActivity } // FIX 3 & 4: These are now resolved
            .receive(on: RunLoop.main)
            .sink { [weak self] activity in
                guard let self = self else { return }
                
                print("Received HealthKit log: \(activity.type)")
                
                // Refill stats based on activity
                switch activity.type {
                case .sleep:
                    // Full sleep refill
                    self.userProfile.mentalHealth = 1.0
                    self.avatar.statusMessage = "Well rested!"
                case .mindfulness:
                    self.logMindfulnessSession()
                case .exercise:
                    self.logExercise()
                }
                
                // Re-evaluate and save
                self.evaluateAvatarState()
                self.saveProfile()
            }
    }
    
    // MARK: - Button Taps & Navigation

    func addAlarm(_ alarm: AppAlarm) {
        notificationManager.scheduleNotification(
            title: "Time to Sleep!",
            body: "Your 3K Athlete is ready for bed.",
            date: alarm.date // FIX 5: The property is 'date', not 'time'
        )
    }
    
    func challengesButtonTapped() {
        print("Challenges tapped")
        // Show GameKit challenges
    }
    
    func profileButtonTapped() {
        isShowingProfileView = true
    }
    
    func appIconButtonTapped() {
        isShowingProfileView = true
    }
}
