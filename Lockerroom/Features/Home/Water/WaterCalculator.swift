//
//  WaterCalculator.swift
//  Locker Room
//
//  Created by Shiv Kalola on 11/9/25.
//

import Foundation

struct WaterCalculator {
    
    /// Calculates daily water requirement in OUNCES based on weight.
    /// Rule of thumb: 0.5 oz per lb of body weight.
    func calculateDailyRequirement(weightInLbs: Double) -> Double {
        let ounces = weightInLbs * 0.5
        return ounces
    }
}
