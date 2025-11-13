//
//  AvatarStateManager.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/12/25.
//

import Foundation
import UserNotifications
import Combine
import GameKit
import SwiftUI

/// This is the central "brain" of your app. It's an ObservableObject
/// that holds the one source of truth for the athlete's state.
class AvatarStateManager: ObservableObject {
    
    /// This is the property that `HomeViewModel` will subscribe to.
    /// It now correctly uses your external `AthleteState` struct.
    @Published private(set) var athleteState: AthleteState
    
    // *** NEW: Published property to trigger the "set alarm" animation ***
    @Published private(set) var lastAlarmSetTime: Date?
    
    // We can keep the persistence service to save/load state.
    private(set) var persistenceService: PersistenceService // Make internal for test
    
    init(persistenceService: PersistenceService) {
        self.persistenceService = persistenceService
        
        if let savedState = persistenceService.loadAthleteState() {
            self.athleteState = savedState
            print("AvatarStateManager: Successfully loaded saved state.")
        } else {
            print("AvatarStateManager: No saved state found, using initial.")
            self.athleteState = AthleteState.initial
        }
    }
    
    // MARK: - Public API (Called by Feature ViewModels)

    /// Called by SleepViewModel
    func logSleep(hours: Double) {
        let energyGain = hours / 8.0 // Simple logic: 8 hours = 100%
        athleteState.energy = min(athleteState.energy + energyGain, 1.0)
        athleteState.lastSleepTime = Date()
        
        print("State changed: Logged \(hours) hours sleep. Energy is now \(athleteState.energy)")
        saveState()
    }
    
    /// Called by WaterViewModel
    func logWater(ounces: Double) {
        let hydrationGain = ounces / 64.0 // Simple logic: 64oz = 100%
        athleteState.hydration = min(athleteState.hydration + hydrationGain, 1.0)
        athleteState.lastWaterTime = Date()
        
        print("State changed: Logged \(ounces)oz water. Hydration is now \(athleteState.hydration)")
        saveState()
    }
    
    /// Called by ExerciseViewModel
    func logWorkout(minutes: Double, type: String) {
        let energyDrain = minutes / 60.0 * 0.3 // 60 mins drains 30%
        let fitnessGain = minutes / 60.0 * 0.1 // 60 mins gains 10%
        
        athleteState.energy = max(athleteState.energy - energyDrain, 0.0)
        athleteState.fitness = min(athleteState.fitness + fitnessGain, 1.0)
        athleteState.lastWorkoutTime = Date()
        
        print("State changed: Logged \(minutes) mins exercise. Energy is now \(athleteState.energy)")
        saveState()
    }
    
    /// Called by MindfulnessViewModel
    func logMindfulness(minutes: Double) {
        let focusGain = minutes / 10.0 * 0.2 // 10 mins = 20%
        athleteState.mindfulness = min(athleteState.mindfulness + focusGain, 1.0)
        athleteState.lastMindfulnessTime = Date()
        
        print("State changed: Logged \(minutes) mins mindfulness. Focus is now \(athleteState.mindfulness)")
        saveState()
    }
    
    // *** NEW: Called by SleepViewModel to trigger animation ***
    func setAlarm() {
        lastAlarmSetTime = Date()
        print("State changed: Alarm set")
        // No saveState() needed, this is a transient event
    }
    
    // MARK: - Private Logic
    
    private func saveState() {
        persistenceService.save(athleteState: athleteState)
        print("AvatarStateManager: State saved successfully.")
    }
}
