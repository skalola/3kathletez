//
//  SleepViewModel.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/9/25.
//
import Foundation
import Combine
import UserNotifications
import MapKit // Import MapKit

enum SleepViewTab {
    case plan, log
}

class SleepViewModel: ObservableObject {
    
    // --- Dependencies ---
    
    // *** FIX: Removed `private(set)` ***
    // This makes the setter 'internal', allowing SleepView to update it.
    var stateManager: AvatarStateManager
    
    private let notificationManager = NotificationManager.shared
    private let sleepCalculator = SleepCalculator()
    
    // *** NEW: Holds the MapViewModel to get commute time ***
    @Published var mapViewModel: MapViewModel
    
    private var cancellables = Set<AnyCancellable>()

    // --- UI State for BOTH tabs ---
    @Published var selectedTab: SleepViewTab = .plan
    
    // Tab 1: Planning
    /// This is the "Start My Day" time (e.g., 8:00 AM)
    @Published var finalWakeUpTime: Date = Date()
    @Published var routineTime: Double = 30 // minutes
    @Published var commuteTime: TimeInterval = 0 // seconds
    
    /// The 4 recommended bedtimes to display in the UI
    @Published var recommendedBedtimes: [Date] = []
    
    // Tab 2: Logging
    @Published var sleepStartTime: Date = Date().addingTimeInterval(-8 * 3600)
    @Published var sleepEndTime: Date = Date()
    
    // --- Alarms ---
    @Published var alarms: [AppAlarm] = []

    init(stateManager: AvatarStateManager) {
        self.stateManager = stateManager
        self.mapViewModel = MapViewModel() // Create the map view model
        self.alarms = notificationManager.loadAlarms()
        
        // Setup default "Start My Day" time
        var components = Calendar.current.dateComponents([.hour, .minute], from: Date())
        components.hour = 8
        components.minute = 0
        self.finalWakeUpTime = Calendar.current.date(from: components) ?? Date()
        
        // --- Smart Calculation Pipeline ---
        
        // 1. Recalculate bedtimes when any input changes
        Publishers.CombineLatest3($finalWakeUpTime, $routineTime, $commuteTime)
            .sink { [weak self] (wakeUp, routine, commute) in
                self?.calculateRecommendedBedtimes(
                    wakeUp: wakeUp,
                    routine: routine * 60, // convert mins to seconds
                    commute: commute
                )
            }
            .store(in: &cancellables)
        
        // 2. When the destination changes, recalculate commute time
        mapViewModel.$selectedDestination
            .sink { [weak self] _ in
                self?.mapViewModel.calculateCommuteTime()
            }
            .store(in: &cancellables)
        
        // 3. When commute time is calculated, update our local property
        mapViewModel.$expectedCommuteTime
            .assign(to: &$commuteTime)
    }
    
    // MARK: - Sleep Calculation Logic
    
    func calculateRecommendedBedtimes(wakeUp: Date, routine: TimeInterval, commute: TimeInterval) {
        self.recommendedBedtimes = sleepCalculator.calculateRecommendedBedtimes(
            finalWakeUpTime: wakeUp,
            routineDuration: routine,
            commuteDuration: commute
        )
    }

    // MARK: - Notification & Alarm Logic

    func scheduleAlarm() {
        // 1. Calculate the *actual* wake-up time (Start Time - Buffers)
        let totalBuffers = (routineTime * 60) + commuteTime
        let actualWakeUpTime = finalWakeUpTime.addingTimeInterval(-totalBuffers)

        // 2. Create the morning alarm model
        let alarm = AppAlarm(
            id: UUID().uuidString,
            time: actualWakeUpTime,
            isEnabled: true
        )
        
        alarms.append(alarm)
        
        // 3. Schedule the *morning* wake-up alarm
        notificationManager.scheduleWakeUpAlarm(for: alarm)
        
        // 4. Schedule the *evening* reminder notification
        notificationManager.scheduleBedtimeReminder(bedtimes: self.recommendedBedtimes)
        
        // 5. Save all alarms
        notificationManager.saveAlarms(alarms)
        
        // 6. Trigger the one-shot animation
        stateManager.setAlarm()
    }
    
    func toggleAlarm(alarm: AppAlarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index].isEnabled.toggle()
            if alarms[index].isEnabled {
                notificationManager.scheduleWakeUpAlarm(for: alarms[index])
            } else {
                notificationManager.cancelNotification(for: alarms[index])
            }
            notificationManager.saveAlarms(alarms)
        }
    }
    
    func deleteAlarm(alarm: AppAlarm) {
        alarms.removeAll { $0.id == alarm.id }
        notificationManager.cancelNotification(for: alarm)
        notificationManager.saveAlarms(alarms)
    }
    
    // MARK: - Log Sleep Function
    
    func logSleep() {
        let durationInSeconds = sleepEndTime.timeIntervalSince(sleepStartTime)
        let durationInHours = durationInSeconds / 3600
        
        if durationInHours > 0 {
            stateManager.logSleep(hours: durationInHours)
        } else {
            print("SleepViewModel: Error - Sleep duration must be positive.")
        }
    }
}
