//
//  SleepCalculator.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/9/25.
//
import Foundation

struct SleepCalculator {
    
    // The "fall asleep" buffer you mentioned
    private let fallAsleepBuffer: TimeInterval = 15 * 60 // 15 minutes in seconds

    // The 90-minute sleep cycles (4.5h, 6h, 7.5h, 9h)
    private let sleepCyclesInSeconds: [TimeInterval] = [
        (9.0 * 3600), // 9 hours
        (7.5 * 3600), // 7.5 hours
        (6.0 * 3600), // 6 hours
        (4.5 * 3600)  // 4.5 hours
    ]
    
    /// This is the upgraded "smart" calculator, based on your wakerapper logic.
    /// It calculates 4 recommended bedtimes based on sleep cycles and buffers.
    ///
    /// - Parameters:
    ///   - finalWakeUpTime: The time the user must be *awake* (e.g., 8:00 AM).
    ///   - routineDuration: The user's pre-sleep routine (in seconds).
    ///   - commuteDuration: The calculated commute time (in seconds).
    /// - Returns: An array of 4 recommended bedtimes.
    func calculateRecommendedBedtimes(
        finalWakeUpTime: Date,
        routineDuration: TimeInterval,
        commuteDuration: TimeInterval
    ) -> [Date] {
        
        // 1. Calculate the *actual* time the user must wake up to make it on time.
        //    (e.g., 8:00 AM "Start Day" - 30m commute - 15m routine = 7:15 AM)
        let totalPrepTime = routineDuration + commuteDuration
        let actualWakeUpTime = finalWakeUpTime.addingTimeInterval(-totalPrepTime)
        
        // 2. Calculate the 4 bedtimes by subtracting sleep cycles from the *actual* wake-up time,
        //    plus the 15-minute buffer to fall asleep.
        let targetGoToSleepTime = actualWakeUpTime.addingTimeInterval(-fallAsleepBuffer)
        
        let recommendedTimes = sleepCyclesInSeconds.map { cycleDuration in
            return targetGoToSleepTime.addingTimeInterval(-cycleDuration)
        }
        
        // Return in order from earliest (9h) to latest (4.5h)
        return recommendedTimes.sorted()
    }
}
