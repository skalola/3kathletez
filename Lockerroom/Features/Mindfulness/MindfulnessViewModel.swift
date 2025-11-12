import Foundation
import Combine

// This is an inferred structure based on the error, as the file
// was not provided in the last turn.

@MainActor
class MindfulnessViewModel: ObservableObject {
    
    @Published var timerValue: Double = 0
    @Published var isTimerRunning: Bool = false
    @Published var sessionDuration: TimeInterval = 60 // Default 1 minute
    
    private var timer: Timer?
    
    func startSession() {
        // In a real app, you'd have timer logic here
        isTimerRunning = true
        print("Mindfulness session started.")
    }
    
    /// Called when the user ends the session.
    func logSession(on homeViewModel: HomeViewModel) {
        isTimerRunning = false
        timer?.invalidate()
        
        // FIX 6: The function is 'logMindfulnessSession', not 'logMindfulness'
        homeViewModel.logMindfulnessSession()
        
        print("Mindfulness session logged.")
    }
    
    func setDuration(_ duration: TimeInterval) {
        self.sessionDuration = duration
    }
}
