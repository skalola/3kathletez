//
//  HomeViewModel.swift
//  Locker Room
//
//  Created by Shiv Kalola on 11/9/25.
//

import Foundation
import Combine
import SwiftUI
import GameKit

// --- **** ALL API STRUCTS AND KEYS REMOVED **** ---
// The AvatarService now handles all 3D asset logic.


class HomeViewModel: ObservableObject {
    
    // --- **** AVATAR SERVICE REFERENCE **** ---
    // We get this from the environment, but it's good practice
    // for the ViewModel to hold a reference.
    private let avatarService = AvatarService.shared
    // --- **** END **** ---
    
    @Published var avatar = Avatar()
    @Published var userProfile = UserProfile()
    
    // --- Sheet Presentation ---
    @Published var isShowingSleepView = false
    @Published var isShowingMindfulnessView = false
    @Published var isShowingExerciseView = false
    @Published var isShowingProfileView = false
    
    // --- UI State ---
    @Published var isActionMenuVisible: Bool = false
    @Published var playerAvatarImage: Image = Image(systemName: "person.circle.fill")
    
    // --- Water State Properties ---
    @Published var waterGoalMessage: String = ""
    @Published var isHydrating: Bool = false
    
    // --- ALARM ARRAYS ---
    @Published var alarms: [AppAlarm] = []
    private let alarmsKey = "3KSportzAlarms"
    
    // --- Services ---
    private var persistenceService = PersistenceService()
    private let waterCalculator = WaterCalculator()
    private let exerciseService = ExerciseService()
    private let mindfulnessService = MindfulnessService()
    
    private var stateTimer: AnyCancellable?
    
    var hasConfiguredAvatar: Bool {
        return !userProfile.avatarURL.isEmpty
    }
    
    let ouncesPerTap = 8.0 // Log 8oz (a cup) per tap
    let sessionCount = 3
    var ouncesPerSession: Double {
        return waterCalculator.calculateDailyRequirement(weightInLbs: userProfile.weightInLbs) / Double(sessionCount)
    }
    
    init() {
        loadData()
        updateAvatarStatus(runEvaluation: false)
        checkDailyWaterReset()
        
        stateTimer = Timer.publish(every: 10.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkCurrentAvatarState()
            }
    }
    
    func appDidBecomeActive() {
        print("App became active, checking for daily reset...")
        checkDailyWaterReset()
    }
    
    func loadData() {
        self.userProfile = persistenceService.loadProfile()
        loadAlarms()
        loadPlayerAvatar()
        
        // --- **** THIS IS THE FIX **** ---
        // If we have a saved URL, tell the AvatarService to load it.
        // The service will handle caching automatically.
        if !userProfile.avatarURL.isEmpty, let url = URL(string: userProfile.avatarURL) {
            print("HomeViewModel: Profile loaded. Telling AvatarService to load model.")
            avatarService.loadAvatar(from: url)
        } else {
            print("HomeViewModel: Profile loaded, but no avatarURL is saved.")
        }
        // --- **** END FIX **** ---
    }
    
    func saveData() {
        persistenceService.saveProfile(userProfile)
    }
    
    func loadPlayerAvatar() {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        
        GKLocalPlayer.local.loadPhoto(for: .normal) { image, error in
            DispatchQueue.main.async {
                if let img = image {
                    self.playerAvatarImage = Image(uiImage: img)
                } else if let error = error {
                    print("Error loading player photo: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - INTENT FUNCTIONS
    
    func sleepButtonTapped() { isShowingSleepView = true }
    func mindfulnessButtonTapped() { isShowingMindfulnessView = true }
    func exerciseButtonTapped() { isShowingExerciseView = true }
    func profileButtonTapped() { isShowingProfileView = true }
    func challengesButtonTapped() { print("Challenges Tapped!") }
    
    func appIconButtonTapped() {
        if hasConfiguredAvatar {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                isActionMenuVisible.toggle()
            }
        } else {
            isShowingProfileView = true
        }
    }
    
    func saveAvatar(id: String) {
        var finalID = id.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if finalID.hasPrefix("https://") {
            if let idFromUrl = finalID.split(separator: "/").last {
                finalID = String(idFromUrl)
            }
        }
        if finalID.hasSuffix(".glb") {
            finalID = finalID.replacingOccurrences(of: ".glb", with: "")
        }
        if finalID.hasSuffix(".usdz") {
            finalID = finalID.replacingOccurrences(of: ".usdz", with: "")
        }
        
        guard !finalID.isEmpty else {
            print("Avatar ID was empty after trimming, not saving.")
            return
        }
        
        let modelUrl = "https://models.readyplayer.me/\(finalID).glb"
        userProfile.avatarURL = modelUrl
        saveData()
        print("New remote avatar URL saved: \(modelUrl)")

        // --- **** THIS IS THE FIX **** ---
        // Now that we've saved the URL, tell the AvatarService
        // to go download this new model.
        if let url = URL(string: modelUrl) {
            avatarService.loadAvatar(from: url)
        }
        
        // We also need to ask the user for gender. For now,
        // we'll just default to neutral.
        // A better solution would be a picker in ProfileView.
        userProfile.avatarGender = "neutral"
        // --- **** END FIX **** ---
        
        avatar.mentalHealth = min(1.0, avatar.mentalHealth + 0.05)
        avatar.statusMessage = "Looking sharp!"
        updateAvatarStatus()
    }

    // --- **** FETCH AVATAR GENDER REMOVED **** ---
    // This API call is no longer needed. We'll set gender
    // manually for now.
    
    
    func logAlarmSet() {
        avatar.mentalHealth = min(1.0, avatar.mentalHealth + 0.30)
        avatar.physicalHealth = min(1.0, avatar.physicalHealth + 0.30)
        updateAvatarStatus()
    }
    
    func logSleep(schedule: SleepSchedule, hoursSlept: Double) {
        let boost = SleepCalculator().calculateMentalBoost(
            hoursSlept: hoursSlept,
            targetHours: userProfile.targetSleepHours
        )
        avatar.mentalHealth = min(1.0, avatar.mentalHealth + boost)
        
        let totalCups = waterCalculator.calculateDailyRequirement(weightInLbs: userProfile.weightInLbs) / 8.0
        
        NotificationManager.shared.scheduleWaterNotifications(
            wakeUpTime: schedule.recommendedWakeUp,
            earliestBedtime: schedule.recommendedBedtimes.first ?? Date(),
            totalCups: Int(totalCups.rounded())
        )
        
        updateAvatarStatus()
    }
    
    
    func logWaterAndAnimate() {
        
        // This logic is simplified to always play the animation
        // but only log water if the goal isn't met.
        
        if userProfile.currentWaterOunces < waterCalculator.calculateDailyRequirement(weightInLbs: userProfile.weightInLbs) {
            userProfile.currentWaterOunces += ouncesPerTap
            saveData()
            
            avatar.mentalHealth = min(1.0, avatar.mentalHealth + 0.005)
            avatar.physicalHealth = min(1.0, avatar.physicalHealth + 0.005)
            avatar.statusMessage = "Ahhh, water's so good!"
        } else {
            avatar.statusMessage = "Hydration goal met!"
            print("logWaterAndAnimate: Goal met, but animating anyway.")
        }

        // --- This logic remains the same ---
        isHydrating = true
        avatar.currentState = .drinking
        print("logWaterAndAnimate: State set to .drinking. View should update.")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if self.avatar.currentState == .drinking {
                self.isHydrating = false
                self.updateAvatarStatus()
                print("logWaterAndAnimate: 3-second timer finished. Reverting to idle state.")
            }
        }
    }

    func logMindfulness(minutes: Int) {
        guard minutes > 0 else { return }
        avatar.mentalHealth = min(1.0, avatar.mentalHealth + 0.20)
        avatar.physicalHealth = min(1.0, avatar.physicalHealth + 0.10)
        updateAvatarStatus()
    }
    
    func logExercise(minutes: Int) {
        guard minutes > 0 else { return }
        let boost = Double(minutes) * 0.01
        avatar.physicalHealth = min(1.0, avatar.physicalHealth + boost)
        avatar.mentalHealth = min(1.0, avatar.mentalHealth + boost)
        updateAvatarStatus()
    }
    
    func addAlarm(_ alarm: AppAlarm) {
        alarms.append(alarm)
        saveAlarms()
        avatar.mentalHealth = min(1.0, avatar.mentalHealth + 0.15)
        updateAvatarStatus()
    }
    
    func toggleAlarm(_ alarm: AppAlarm) {
        guard let index = alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        
        let toggledAlarm = alarms[index]

        if toggledAlarm.isEnabled {
            NotificationManager.shared.scheduleWakeUpAlarm(alarm: toggledAlarm)
        } else {
            NotificationManager.shared.cancelNotifications(with: toggledAlarm.notificationIDs)
            alarms[index].notificationIDs = []
        }
        saveAlarms()
    }

    func deleteAlarm(at offsets: IndexSet) {
        var idsToDelete = Set<UUID>()
        for index in offsets {
            if index < alarms.count { idsToDelete.insert(alarms[index].id) }
        }
        
        if idsToDelete.isEmpty { return }
        
        let notificationIDsToCancel = alarms
            .filter { idsToDelete.contains($0.id) && $0.isEnabled }
            .flatMap { $0.notificationIDs }

        if !notificationIDsToCancel.isEmpty {
            NotificationManager.shared.cancelNotifications(with: notificationIDsToCancel)
        }
        
        alarms.removeAll { idsToDelete.contains($0.id) }
        saveAlarms()
    }
    
    // MARK: - Daily Water Evaluation
    
    private func checkDailyWaterReset() {
        if !Calendar.current.isDateInToday(userProfile.lastWaterEvaluationDate) {
            evaluateDailyWater()
        }
    }
    
    private func evaluateDailyWater() {
        let dailyGoalOunces = waterCalculator.calculateDailyRequirement(weightInLbs: userProfile.weightInLbs)
        
        if userProfile.currentWaterOunces >= (dailyGoalOunces * 0.8) {
            avatar.mentalHealth = min(1.0, avatar.mentalHealth + 0.25)
            avatar.physicalHealth = min(1.0, avatar.physicalHealth + 0.25)
            avatar.statusMessage = "P-Status: Goal Crushed!"
        } else {
            avatar.mentalHealth = max(0.0, avatar.mentalHealth - 0.50)
            avatar.physicalHealth = max(0.0, avatar.physicalHealth - 0.50) // Fix: was - 50
            avatar.statusMessage = "P-Status: Hydration Failed (-50%)"
        }
        
        userProfile.currentWaterOunces = 0.0
        userProfile.lastWaterEvaluationDate = Date()
        saveData()
        updateAvatarStatus()
    }
    
    // MARK: - Tamagotchi State Engine
    
    func checkCurrentAvatarState() {
        updateAvatarStatus()
    }
    
    
    func updateAvatarStatus(runEvaluation: Bool = true) {
        
        guard !isHydrating else {
            print("updateAvatarStatus: isHydrating is true. State will remain .drinking.")
            return
        }
        
        let now = Date()
        if let activeSleep = alarms.first(where: { $0.isEnabled && $0.wakeUpTime > now }) {
            if let firstBedtime = activeSleep.bedTimes.first, now >= firstBedtime && now <= activeSleep.wakeUpTime {
                avatar.currentState = .sleeping
                return
            }
        }
        
        if avatar.mentalHealth > 0.8 && avatar.physicalHealth > 0.8 {
            avatar.currentState = .elite
            avatar.statusMessage = "P-Status: Elite!"
        } else if avatar.physicalHealth < 0.2 {
            avatar.currentState = .lowEnergy
            avatar.statusMessage = "P-Status: Low Energy"
        } else if userProfile.currentWaterOunces < (ouncesPerSession * 0.5) {
            avatar.currentState = .thirsty
            avatar.statusMessage = "P-Status: Thirsty"
        } else {
            avatar.currentState = .idle
            avatar.statusMessage = "Ready to train!"
        }
    }
    
    // MARK: - Persistence
    
    private func saveAlarms() {
        do {
            let data = try JSONEncoder().encode(alarms)
            UserDefaults.standard.set(data, forKey: alarmsKey)
        } catch {
            print("Failed to save alarms: \(error.localizedDescription)")
        }
    }
    
    private func loadAlarms() {
        guard let data = UserDefaults.standard.data(forKey: alarmsKey) else { return }
        
        do {
            alarms = try JSONDecoder().decode([AppAlarm].self, from: data)
        } catch {
            print("Failed to load alarms: \(error.localizedDescription)")
        }
    }
}
