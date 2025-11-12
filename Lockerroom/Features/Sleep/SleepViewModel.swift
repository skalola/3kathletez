//
//  SleepViewModel.swift
//  Locker Room
//
//  Created by Shiv Kalola on 11/9/25.
//

import Foundation
import Combine
import UserNotifications
import SwiftUI // <-- NEW: Import SwiftUI to fix 'withAnimation'

@MainActor
class SleepViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var arrivalTime = Date()
    @Published var routineTime: Double = 30
    @Published var travelTime: TimeInterval = 0
    @Published var repeatFrequency: AlarmRepeatFrequency = .once
    @Published var isAddingCommute = false
    @Published var soundName: String = "Default"
    
    @Published var hasNotificationAccess = false
    @Published var isShowingMapView = false
    @Published var isShowingSoundPicker = false
    @Published var travelTimeMessage: String = ""
    @Published var travelDestinationName: String = ""
    @Published var isCalculating: Bool = false

    @Published var schedule: SleepSchedule?
    
    // --- THIS IS THE FIX ---
    // The ViewModel now owns its own alarms again.
    @Published var alarms: [AppAlarm] = []
    private let alarmsKey = "3KSportzAlarms" // A dedicated key for sleep alarms
    
    // --- END FIX ---

    let bedTimeLabels: [String] = [
        "6 CYCLES (9H)",
        "5 CYCLES (7.5H)",
        "4 CYCLES (6H)",
        "3 CYCLES (4.5H)"
    ]
    @Published var bedTimeStrings: [String] = ["-", "-", "-", "-"]
    
    private let calculator = SleepCalculator()
    
    // --- THIS IS THE FIX ---
    // The 'onAlarmSet' callback is only for the 30% boost.
    var onAlarmSet: (AppAlarm) -> Void
    
    // FIX 2: Change init to reflect the new signature
    init(onAlarmSet: @escaping (AppAlarm) -> Void) {
        self.onAlarmSet = onAlarmSet
        // ... (rest of init)
        
        if let defaultTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) {
            self.arrivalTime = defaultTime
        }
        loadAlarms()
        checkNotificationAccess()
    }
    
    // MARK: - Permissions
    
    func requestNotificationAccess() {
        NotificationManager.shared.requestPermission { granted in
            DispatchQueue.main.async {
                self.hasNotificationAccess = granted
            }
        }
    }
    
    func checkNotificationAccess() {
        NotificationManager.shared.checkPermission { granted in
            DispatchQueue.main.async {
                self.hasNotificationAccess = granted
            }
        }
    }
    
    // MARK: - Core Logic
    
    private func getNextArrivalTime() -> Date {
        let calendar = Calendar.current
        let now = Date()
        let timeComponents = calendar.dateComponents([.hour, .minute], from: arrivalTime)
        
        guard var nextArrival = calendar.nextDate(after: now, matching: timeComponents, matchingPolicy: .nextTime) else {
            return now.addingTimeInterval(86400) // Fallback
        }
        
        let buffer = (routineTime * 60) + (isAddingCommute ? travelTime : 0)
        
        if nextArrival.timeIntervalSinceNow < buffer {
             nextArrival = calendar.date(byAdding: .day, value: 1, to: nextArrival) ?? nextArrival
        }
        
        return nextArrival
    }
    
    func calculateSchedule() {
        isCalculating = true
        schedule = nil
        
        Task {
            try? await Task.sleep(for: .seconds(2))
            
            let routineTimeInSeconds = routineTime * 60
            let finalArrivalTime = getNextArrivalTime()
            let finalTravelTime = isAddingCommute ? travelTime : 0
            
            let newSchedule = calculator.calculateSchedule(
                desiredArrivalTime: finalArrivalTime,
                routineDuration: routineTimeInSeconds,
                travelTime: finalTravelTime
            )
            
            // --- FIX: Removed 'withAnimation' from ViewModel ---
            // The View will handle animating this change.
            await MainActor.run {
                self.schedule = newSchedule
                
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                self.bedTimeStrings = newSchedule.recommendedBedtimes.map { formatter.string(from: $0) }
                
                self.isCalculating = false
            }
        }
    }
    
    func setAlarm() {
        guard let wakeUpTime = schedule?.recommendedWakeUp, let bedTimes = schedule?.recommendedBedtimes else { return }
        
        var newAlarm = AppAlarm(
            wakeUpTime: wakeUpTime,
            bedTimes: bedTimes,
            repeatFrequency: repeatFrequency,
            soundName: soundName
        )
        
        let notificationIDs = NotificationManager.shared.scheduleWakeUpAlarm(alarm: newAlarm)
        newAlarm.notificationIDs = notificationIDs
        newAlarm.isEnabled = true
        
        alarms.append(newAlarm)
        saveAlarms()
        
        // --- FIX 3: Call the callback WITH the new alarm ---
        onAlarmSet(newAlarm)
    }

    func toggleAlarm(_ alarm: AppAlarm) {
        guard let index = alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        
        // This is the safe toggle logic
        // The View passes the *new* state, so we just read it.
        let toggledAlarm = alarms[index]

        if toggledAlarm.isEnabled {
            let newNotificationIDs = NotificationManager.shared.scheduleWakeUpAlarm(alarm: toggledAlarm)
            alarms[index].notificationIDs = newNotificationIDs
        } else {
            NotificationManager.shared.cancelNotifications(with: toggledAlarm.notificationIDs)
            alarms[index].notificationIDs = []
        }
        
        saveAlarms()
    }
    
    func deleteAlarm(at offsets: IndexSet) {
        // This is the safe delete logic
        var idsToDelete = Set<UUID>()
        for index in offsets {
            if index < alarms.count {
                idsToDelete.insert(alarms[index].id)
            }
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
    
    func toggleCommute() {
        if !isAddingCommute {
            travelTime = 0
            travelTimeMessage = ""
            travelDestinationName = ""
        }
        
        if schedule != nil {
            calculateSchedule()
        }
    }
    
    func commuteButtonTapped() {
        if travelTime == 0 {
            isShowingMapView = true
        } else {
            isAddingCommute.toggle()
            toggleCommute()
        }
    }
    
    func editCommuteTapped() {
        isShowingMapView = true
    }

    // MARK: - Persistence (Now self-contained)
    
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
