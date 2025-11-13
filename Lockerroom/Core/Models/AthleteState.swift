//
//  AthleteState.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/12/25.
//

import Foundation
import UserNotifications
import Combine
import GameKit
import SwiftUI

/// A single, unified struct that represents the avatar's complete state.
/// This is the "single source of truth."
struct AthleteState: Codable, Equatable {
    
    // Core Vitals (range 0.0 to 1.0)
    var energy: Double
    var hydration: Double
    var mindfulness: Double
    var fitness: Double // Renamed from exercise/strength for clarity
    
    // Last Logged Activities
    var lastSleepTime: Date?
    var lastWaterTime: Date?
    var lastWorkoutTime: Date?
    var lastMindfulnessTime: Date?

    // Computed Properties for the "Tamagotchi" logic
    var mood: Mood {
        if energy < 0.2 {
            return .tired
        }
        if hydration < 0.3 {
            return .thirsty
        }
        if fitness > 0.9 && energy > 0.8 {
            return .energized
        }
        return .neutral
    }
    
    enum Mood {
        case neutral, happy, sad, tired, thirsty, energized, sleeping
    }
    
    // Initial state for a new user
    static var initial: AthleteState {
        AthleteState(
            energy: 0.7,
            hydration: 0.7,
            mindfulness: 0.5,
            fitness: 0.3
        )
    }
}
