//
//  ExerciseService.swift
//  Locker Room
//
//  Created by Shiv Kalola on 11/9/25.
//

import Foundation

struct ExerciseService {
    
    // We can make this much smarter later, using weight, duration, and
    // Apple HealthKit data to get a real calorie burn.
    func calculatePhysicalBoost(minutes: Int, weightInLbs: Double) -> Double {
        if minutes >= 30 {
            return 0.15 // 15% boost
        } else if minutes > 0 {
            return 0.05 // 5% boost
        }
        return 0.0
    }
}
