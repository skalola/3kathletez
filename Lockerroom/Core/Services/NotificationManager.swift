//
//  NotificationManager.swift
//  Locker Room
//
//  Created by Shiv Kalola on 11/9/25.
//

import Foundation
import UserNotifications

class NotificationManager {
    
    static let shared = NotificationManager()
    private init() {}
    
    func checkPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            completion(settings.authorizationStatus == .authorized)
        }
    }
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound, .criticalAlert]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
            completion(granted)
        }
    }
    
    func scheduleWakeUpAlarm(alarm: AppAlarm) -> [String] {
        var notificationIDs: [String] = []
        
        // --- FIX 1: Accessing non-optional properties directly ---
        let bedTimes = alarm.bedTimes
        let soundName = alarm.soundName
        // --- END FIX 1 ---
        
        let content = UNMutableNotificationContent()
        content.title = "Time to Wake Up!"
        content.body = "Time to start your day and feed your athlete!"
        
        if soundName == "Default" {
            content.sound = .defaultCritical
        } else {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(soundName))
        }
        
        var dateComponents: DateComponents
        let repeats: Bool
        
        // --- FIX 2: Using correct property name (.wakeUpTime) ---
        switch alarm.repeatFrequency {
        case .once:
            dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: alarm.wakeUpTime)
            repeats = false
        case .daily:
            dateComponents = Calendar.current.dateComponents([.hour, .minute], from: alarm.wakeUpTime)
            repeats = true
        case .weekly:
            dateComponents = Calendar.current.dateComponents([.hour, .minute, .weekday], from: alarm.wakeUpTime)
            repeats = true
        }
        // --- END FIX 2 ---
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: repeats)
        let id = "ALARM-\(alarm.id.uuidString)"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
        notificationIDs.append(id)
        
        let bedtimeTitles = ["Optimal Bedtime", "Good Bedtime", "OK Bedtime", "Minimum Bedtime"]
        
        for (index, time) in bedTimes.reversed().enumerated() {
            let bedtimeContent = UNMutableNotificationContent()
            bedtimeContent.title = "Bedtime Reminder (\(bedtimeTitles[index]))"
            
            let hoursOfSleep = 9.0 - (Double(index) * 1.5)
            bedtimeContent.body = "Time to go to bed to get your \(hoursOfSleep) hours of sleep."

            bedtimeContent.sound = .default
            
            let bedtimeComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: time)
            let bedtimeTrigger = UNCalendarNotificationTrigger(dateMatching: bedtimeComponents, repeats: false)
            let bedtimeID = "BEDTIME-\(alarm.id.uuidString)-\(index)"
            let bedtimeRequest = UNNotificationRequest(identifier: bedtimeID, content: bedtimeContent, trigger: bedtimeTrigger)
            UNUserNotificationCenter.current().add(bedtimeRequest)
            notificationIDs.append(bedtimeID)
        }
        
        return notificationIDs
    }
    
    func scheduleWaterNotifications(wakeUpTime: Date, earliestBedtime: Date, totalCups: Int) {
        let notificationManager = UNUserNotificationCenter.current()
        
        // Calculate offsets in seconds (1 hour = 3600s)
        let oneHour: TimeInterval = 3600
        let eightHours: TimeInterval = 8 * 3600
        
        // 1. Morning Reminder (1 hour after wake up)
        let morningTime = wakeUpTime.addingTimeInterval(oneHour)
        let morningComponents = Calendar.current.dateComponents([.hour, .minute], from: morningTime)
        let morningTrigger = UNCalendarNotificationTrigger(dateMatching: morningComponents, repeats: true)
        
        let morningContent = UNMutableNotificationContent()
        morningContent.title = "💧 Morning Hydration"
        morningContent.body = "Good morning! Start your day with some water. Your goal is \(totalCups) cups."
        morningContent.sound = .default
        
        let morningRequest = UNNotificationRequest(identifier: "WATER_MORNING", content: morningContent, trigger: morningTrigger)
        
        // 2. Midday Reminder (8 hours after wake up)
        let middayTime = wakeUpTime.addingTimeInterval(eightHours)
        let middayComponents = Calendar.current.dateComponents([.hour, .minute], from: middayTime)
        let middayTrigger = UNCalendarNotificationTrigger(dateMatching: middayComponents, repeats: true)
        
        let middayContent = UNMutableNotificationContent()
        middayContent.title = "💧 Afternoon Hydration"
        middayContent.body = "Don't forget to hydrate! You have about \(totalCups / 2) cups to go."
        middayContent.sound = .default
        
        let middayRequest = UNNotificationRequest(identifier: "WATER_MIDDAY", content: middayContent, trigger: middayTrigger)
        
        // 3. Evening Reminder (1 hour before earliest bed time)
        let eveningTime = earliestBedtime.addingTimeInterval(-oneHour)
        let eveningComponents = Calendar.current.dateComponents([.hour, .minute], from: eveningTime)
        let eveningTrigger = UNCalendarNotificationTrigger(dateMatching: eveningComponents, repeats: true)
        
        let eveningContent = UNMutableNotificationContent()
        eveningContent.title = "💧 Final Hydration"
        eveningContent.body = "Last call for water! Finish up your remaining cups before bed."
        eveningContent.sound = .default
        
        let eveningRequest = UNNotificationRequest(identifier: "WATER_EVENING", content: eveningContent, trigger: eveningTrigger)
        
        // Add all requests
        notificationManager.add(morningRequest)
        notificationManager.add(middayRequest)
        notificationManager.add(eveningRequest)
    }
    
    func cancelNotifications(with ids: [String]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
}
