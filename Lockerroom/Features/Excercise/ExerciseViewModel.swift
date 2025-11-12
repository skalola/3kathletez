//
//  ExerciseViewModel.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/9/25.
//

import Foundation
import SwiftUI
import GameKit
import Combine

@MainActor
class ExerciseViewModel: ObservableObject {
    
    @Published var selectedActivity: String?
    @Published var logMinutes: Double = 0
    @Published var loggedActivities: [LoggedActivity] = []
    
    // This is where we will save the log
    private let logKey = "3KExerciseLog"
    
    // --- IMPORTANT ---
    // You MUST create this ID in App Store Connect
    let leaderboardID = "total_exercise_minutes"
    
    var activityTypes = [
        ("Walking", "figure.walk"),
        ("Running", "figure.run"),
        ("Weights", "figure.strengthtraining.traditional"),
        ("Basketball", "figure.basketball"),
        ("Football", "figure.american.football"),
        ("Baseball", "figure.baseball"),
        ("Hockey", "figure.hockey"),
        ("Pickleball", "figure.pickleball"),
        ("Tennis", "figure.tennis"),
        ("Cricket", "figure.cricket"),
        ("Soccer", "figure.soccer"),
        ("Boxing", "figure.boxing"),
        ("MMA", "figure.mixed.martial.arts")
    ]
    
    init() {
        loadLog() // Load previous logs
    }
    
    func selectActivity(_ name: String) {
        selectedActivity = name
        logMinutes = 30 // Default to 30 mins
    }
    
    func logActivity(homeViewModel: HomeViewModel) {
        guard let selectedActivity = selectedActivity else { return }
        let minutes = Int(logMinutes)
        
        // Find the icon for the selected activity
        let iconName = activityTypes.first(where: { $0.0 == selectedActivity })?.1 ?? "figure.run"
        
        // 1. Create the log entry
        let newActivity = LoggedActivity(name: selectedActivity, icon: iconName, minutes: minutes, date: Date())
        loggedActivities.append(newActivity)
        saveLog()
        
        // 2. Call HomeViewModel to apply the boost
        homeViewModel.logExercise(minutes: minutes)
        
        // 3. Submit to Game Center
        submitToGameCenter(activity: newActivity)
        
        // 4. Reset
        self.selectedActivity = nil
        self.logMinutes = 0
    }
    
    // --- NEW: Game Center Logic ---
    private func submitToGameCenter(activity: LoggedActivity) {
        guard GKLocalPlayer.local.isAuthenticated else {
            print("Player not authenticated, cannot submit score.")
            return
        }
        
        print("Submitting score to Game Center...")
        
        Task {
            do {
                // 1. Get the player's *current* total score from the leaderboard
                let leaderboards = try await GKLeaderboard.loadLeaderboards(IDs: [leaderboardID])
                guard let leaderboard = leaderboards.first else {
                    print("Could not find leaderboard with ID: \(leaderboardID)")
                    return
                }
                
                let (localPlayerEntry, _) = try await leaderboard.loadEntries(for: [GKLocalPlayer.local], timeScope: .allTime)
                
                let currentScore = localPlayerEntry?.score ?? 0
                let newScore = currentScore + activity.minutesLogged
                
                // 2. Submit the new *total* score
                try await GKLeaderboard.submitScore(
                    newScore,
                    context: 0,
                    player: GKLocalPlayer.local,
                    leaderboardIDs: [leaderboardID]
                )
                
                print("Successfully submitted new total score: \(newScore)")
                
                // 3. (Optional) Grant Achievements
                try await reportAchievements(newTotalMinutes: newScore, activityName: activity.name)
                
            } catch {
                print("Error interacting with Game Center: \(error.localizedDescription)")
            }
        }
    }
    
    private func reportAchievements(newTotalMinutes: Int, activityName: String) async throws {
        var achievementsToReport: [GKAchievement] = []
        
        // Example: Achievement for logging first workout
        let firstWorkout = GKAchievement(identifier: "log_first_workout")
        firstWorkout.percentComplete = 100
        firstWorkout.showsCompletionBanner = true
        achievementsToReport.append(firstWorkout)
        
        // Example: Achievement for logging over 1000 total minutes
        let thousandMinutes = GKAchievement(identifier: "total_1000_minutes")
        thousandMinutes.percentComplete = min(100.0, (Double(newTotalMinutes) / 1000.0) * 100.0)
        thousandMinutes.showsCompletionBanner = thousandMinutes.percentComplete == 100
        achievementsToReport.append(thousandMinutes)
        
        if !achievementsToReport.isEmpty {
            try await GKAchievement.report(achievementsToReport)
            print("Successfully reported \(achievementsToReport.count) achievements.")
        }
    }
    
    // --- NEW: Persistence for Log ---
    private func saveLog() {
        do {
            let data = try JSONEncoder().encode(loggedActivities)
            UserDefaults.standard.set(data, forKey: logKey)
        } catch {
            print("Failed to save exercise log: \(error.localizedDescription)")
        }
    }
    
    private func loadLog() {
        guard let data = UserDefaults.standard.data(forKey: logKey) else { return }
        do {
            loggedActivities = try JSONDecoder().decode([LoggedActivity].self, from: data)
        } catch {
            print("Failed to load exercise log: \(error.localizedDescription)")
        }
    }
}
