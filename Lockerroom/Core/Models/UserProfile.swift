//
//  UserProfile.swift
//  Locker Room
//
//  Created by Shiv Kalola on 11/9/25.
//
//  MODIFIED:
//  - Moved mentalHealth and physicalHealth here from Avatar.swift
//  - This is CRITICAL so these stats are saved by PersistenceService.
//

import Foundation

// This model holds the user's personal data, which
// we need for calculations (like water/exercise) and settings.
struct UserProfile: Codable {
    var userName: String = "Athlete"
    var weightInLbs: Double = 160.0
    var targetSleepHours: Double = 8.0
    
    // --- CORE TAMAGOTCHI STATS ---
    // These are now saved and loaded as part of the user's profile.
    // They range from 0.0 (empty/sick) to 1.0 (full/elite).
    var mentalHealth: Double = 0.5
    var physicalHealth: Double = 0.5
    
    // --- NEW WATER PROPERTIES ---
    var currentWaterOunces: Double = 0.0
    var lastWaterEvaluationDate: Date = Date()
    
    // --- RPM PROPERTIES ---
    var avatarURL: String = ""
    var avatarGender: String = "neutral"

    // We will save and load this struct from UserDefaults
}
