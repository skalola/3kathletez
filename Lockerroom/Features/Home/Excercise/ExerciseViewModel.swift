//
//  ExerciseViewModel.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/9/25.
//

import Foundation
import UserNotifications
import Combine
import GameKit
import SwiftUI


@MainActor
class ExerciseViewModel: ObservableObject {
    
    // 1. Dependency
    // *** FIX: Removed `private(set)` to make setter internal ***
    var stateManager: AvatarStateManager
    
    // 2. UI State
    @Published var duration: Double = 30
    @Published var activityName: String = ""
    @Published var caloriesBurned: String = ""
    @Published var date: Date = Date()
    
    // 3. Inject the dependency
    init(stateManager: AvatarStateManager) {
        self.stateManager = stateManager
    }
    
    // 4. Public function
    func logWorkout() {
        // The VM's only job is to call the state manager.
        stateManager.logWorkout(minutes: duration, type: activityName)
    }
}
