//
//  MindfulnessService.swift
//  Locker Room
//
//  Created by Shiv Kalola on 11/9/25.
//

import Foundation

struct MindfulnessService {
    
    func calculateMentalBoost(minutes: Int) -> Double {
        if minutes >= 10 {
            return 0.05 // 5% boost
        } else if minutes > 0 {
            return 0.01 // 1% boost
        }
        return 0.0
    }
}
