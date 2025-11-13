import Foundation
import UserNotifications
import Combine
import GameKit
import SwiftUI

@MainActor
class MindfulnessViewModel: ObservableObject {
    
    // 1. Dependency
    // *** FIX: Removed `private(set)` to make setter internal ***
    var stateManager: AvatarStateManager
    
    // 2. UI State
    @Published var mindfulnessMinutes: String = "5.0"
    @Published var date: Date = Date()
    
    // 3. Inject the dependency
    init(stateManager: AvatarStateManager) {
        self.stateManager = stateManager
    }
    
    // 4. Public function
    func logSession() {
        // Convert String to Double here
        if let minutes = Double(mindfulnessMinutes) {
            stateManager.logMindfulness(minutes: minutes)
        } else {
            print("MindfulnessViewModel: Invalid number entered: \(mindfulnessMinutes)")
        }
    }
}
