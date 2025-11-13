//
//  WaterViewModel.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/12/25.
//

import Foundation
import Combine

@MainActor
class WaterViewModel: ObservableObject {
    
    // 1. Dependency
    // *** FIX: Removed `private(set)` to make setter internal ***
    var stateManager: AvatarStateManager
    
    // 2. State for the UI
    @Published var waterIntake: String = "8.0" // Default 8oz
    
    // 3. Inject the dependency
    init(stateManager: AvatarStateManager) {
        self.stateManager = stateManager
    }
    
    // 4. Public function for the View to call
    func logWater() {
        // Convert String to Double here
        if let ounces = Double(waterIntake) {
            // This VM just reports an event: "8 oz was added."
            stateManager.logWater(ounces: ounces)
        } else {
            print("WaterViewModel: Invalid number entered: \(waterIntake)")
        }
    }
}
