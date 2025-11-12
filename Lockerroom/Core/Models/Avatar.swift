//
//  Avatar.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/10/25.
//

import Foundation

struct Avatar: Codable {
    
    enum State: Codable, Equatable {
        case idle
        case sleeping
        case thirsty
        case drinking
        case exercising
        case mindfulness
        case elite
        case dehydrated
        case lowEnergy
        
        /// Returns the filename of the local animation asset (without the .glb extension).
        func getAnimationFileName(for gender: String) -> String {
            
            let isMale = (gender == "male" || gender == "masculine")
            
            switch self {
            case .idle:
                let candidates = isMale
                    ? ["M_Standing_Idle_001", "M_Standing_Idle_Variations_001", "Idle"]
                    : ["F_Standing_Idle_001", "F_Standing_Idle_Variations_001", "Idle"]
                return candidates.first!
                
            case .drinking, .thirsty:
                let candidates = isMale
                    ? ["M_Standing_Idle_001", "M_Standing_Expressions_004", "M_Standing_Idle_001"]
                    : ["M_Standing_Idle_001", "F_Standing_Expressions_004", "F_Standing_Idle_001"]
                return candidates.first!

            case .sleeping:
                return "M_Sitting_Pondering_001"
                
            case .exercising, .lowEnergy:
                let candidates = isMale
                    ? ["M_Run_001", "M_Jog_001", "M_Walk_001", "M_Run_Jump_001"]
                    : ["F_Run_001", "F_Jog_001", "F_Walk_001", "F_Run_Jump_001"]
                return candidates.first!

            case .mindfulness:
                return "M_Standing_Idle_001" // Neutral pose is usually masculine-based
                
            case .elite:
                let candidates = isMale
                    ? ["M_Standing_Idle_001", "M_Dances_001"]
                    : ["M_Standing_Idle_001", "F_Dances_001"]
                return candidates.first!
                
            default:
                return isMale ? "M_Standing_Idle_001" : "F_Standing_Idle_001"
            }
        }
    }
    
    var mentalHealth: Double = 0.5
    var physicalHealth: Double = 0.5
    
    var statusMessage: String = "Ready to train!"
    var currentState: State = .idle
}
