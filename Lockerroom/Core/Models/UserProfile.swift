//
//  UserProfile.swift
//  Locker Room
//
//  Created by Shiv Kalola on 11/9/25.
//

import Foundation

// This model holds the user's personal data, which
// we need for calculations (like water/exercise) and settings.
struct UserProfile: Codable {
    var userName: String = "Athlete"
    var weightInLbs: Double = 160.0
    var targetSleepHours: Double = 8.0
    
    // --- NEW WATER PROPERTIES ---
    var currentWaterOunces: Double = 0.0
    var lastWaterEvaluationDate: Date = Date()
    
    // --- RPM PROPERTIES ---
    var avatarURL: String = ""
    var avatarGender: String = "neutral"
    
    // --- **** REMOVED **** ---
    // We no longer need this, as we are loading local files.
    // var availableAnimations: [String] = []
    
    // We will save and load this struct from UserDefaults
}
