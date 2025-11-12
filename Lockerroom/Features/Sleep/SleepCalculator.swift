//
//  SleepCalculator.swift
//  Locker Room
//
//  Created by Shiv Kalola on 11/9/25.
//

import Foundation

// A struct to hold the results of our calculation
struct SleepSchedule {
    let recommendedWakeUp: Date
    let recommendedBedtimes: [Date]
}

// This is your modernized `wakerapper` logic.
// It's a clean "service" that just does calculations.
struct SleepCalculator {
    
    // Sleep cycle durations in hours (9, 7.5, 6, 4.5)
    private let sleepCycleDurations: [TimeInterval] = [
        (9.0 * 3600),
        (7.5 * 3600),
        (6.0 * 3600),
        (4.5 * 3600)
    ]
    
    // 15 minute buffer to fall asleep, in seconds
    private let fallAsleepBuffer: TimeInterval = 15 * 60

    /// This is the main function that mirrors your `wakerapper` logic.
    /// It calculates the 4 bedtimes and 1 wake-up time.
    func calculateSchedule(
        desiredArrivalTime: Date,
        routineDuration: TimeInterval, // in seconds
        travelTime: TimeInterval      // in seconds
    ) -> SleepSchedule {
        
        // 1. Calculate the final "must-wake-up" time
        let totalPrepTime = routineDuration + travelTime
        let recommendedWakeUpTime = desiredArrivalTime.addingTimeInterval(-totalPrepTime)
        
        // 2. Calculate the 4 bedtimes based on sleep cycles
        // We work backwards from the wake-up time.
        var bedtimes: [Date] = []
        
        for cycle in sleepCycleDurations {
            let idealBedtime = recommendedWakeUpTime
                .addingTimeInterval(-cycle) // Subtract the sleep cycle
                .addingTimeInterval(-fallAsleepBuffer) // Subtract the buffer
            
            bedtimes.append(idealBedtime)
        }
        
        // Return the full schedule, sorted from earliest to latest bedtime
        return SleepSchedule(
            recommendedWakeUp: recommendedWakeUpTime,
            recommendedBedtimes: bedtimes.sorted()
        )
    }
    
    // This is the function the HomeViewModel will call
    // after the user *actually* sleeps.
    func calculateMentalBoost(hoursSlept: Double, targetHours: Double) -> Double {
        // Simple logic for now: hitting 80% of your target = 20% boost
        let percentageOfGoal = hoursSlept / targetHours
        return (percentageOfGoal * 0.20)
    }
}
