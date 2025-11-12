//
//  Avatar.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/10/25.
//
//  MODIFIED:
//  - Removed mentalHealth and physicalHealth. They are now in UserProfile.swift
//    to ensure they are persisted. This struct is now just for state.
//  - Updated getAnimationFileName to provide unique animations for
//    passive negative states (.lowEnergy, .dehydrated).
//

import Foundation

struct Avatar: Codable {
    
    enum State: Codable, Equatable {
        case idle
        case sleeping
        case thirsty       // User action: needs to drink
        case drinking      // User action: is drinking
        case exercising
        case mindfulness
        case elite         // High-health state
        case dehydrated    // Passive negative state (low water)
        case lowEnergy     // Passive negative state (low exercise/sleep)
        
        /// Returns the filename of the local animation asset (without the .glb extension).
        func getAnimationFileName(for gender: String) -> String {
            
            let isMale = (gender == "male" || gender == "masculine")
            
            switch self {
            case .idle:
                let candidates = isMale
                    ? ["M_Standing_Idle_001", "M_Standing_Idle_Variations_001", "Idle"]
                    : ["F_Standing_Idle_001", "F_Standing_Idle_Variations_001", "Idle"]
                return candidates.first!
                
            // This is the ACTION of drinking
            case .drinking, .thirsty:
                let candidates = isMale
                    ? ["M_Standing_Idle_001", "M_Standing_Expressions_004", "M_Standing_Idle_001"]
                    : ["M_Standing_Idle_001", "F_Standing_Expressions_004", "F_Standing_Idle_001"]
                return candidates.first!
                
            // This is the ACTION of sleeping
            case .sleeping:
                return "M_Sitting_Pondering_001" // This is a good "calm" or "sleeping" pose
                
            // This is the ACTION of exercising
            case .exercising:
                let candidates = isMale
                    ? ["M_Run_001", "M_Jog_001", "M_Walk_001", "M_Run_Jump_001"]
                    : ["F_Run_001", "F_Jog_001", "F_Walk_001", "F_Run_Jump_001"]
                return candidates.first!

            // This is the PASSIVE "sick" state for low energy
            case .lowEnergy:
                // Use a "pondering" or "sad" pose, definitely not running
                return "M_Sitting_Pondering_001"
            
            // This is the PASSIVE "sick" state for dehydration
            case .dehydrated:
                // Use an "expression" pose that looks tired or panting
                return "M_Standing_Expressions_005"

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
    
    // These stats are no longer stored here. They are in UserProfile.
    // var mentalHealth: Double = 0.5
    // var physicalHealth: Double = 0.5
    
    var statusMessage: String = "Ready to train!"
    var currentState: State = .idle
}
