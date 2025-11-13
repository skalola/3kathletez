//
//  NotificationManager.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/9/25.
//
import Foundation
import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    
    static let shared = NotificationManager()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let persistenceService = PersistenceService()

    // *** FIX: Changed to public ***
    override init() {
        super.init()
        notificationCenter.delegate = self
    }
    
    /// Requests permission to send notifications.
    func requestAuthorization() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Alarm Scheduling

    /// Schedules the primary *morning* wake-up alarm.
    func scheduleWakeUpAlarm(for alarm: AppAlarm) {
        let content = UNMutableNotificationContent()
        content.title = "Time to Wake Up!"
        content.body = "Your Lockerroom alarm is going off."
        // Use the sound file from your wakerapper project
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "loud_alarm.caf"))
        content.userInfo = ["alarmID": alarm.id]
        
        // This category is from your old project, for handling snooze/stop
        content.categoryIdentifier = "ALARM_CATEGORY"

        let components = Calendar.current.dateComponents([.hour, .minute], from: alarm.time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false) // Not repeating
        let request = UNNotificationRequest(identifier: alarm.id, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling wake-up alarm: \(error.localizedDescription)")
            } else {
                print("Successfully scheduled wake-up alarm for \(alarm.time)")
            }
        }
    }
    
    /// *** NEW: Schedules the *evening* notification to recommend bedtimes ***
    func scheduleBedtimeReminder(bedtimes: [Date]) {
        guard let earliestBedtime = bedtimes.first else { return }
        
        // Schedule the reminder 30 minutes before the *earliest* recommended bedtime
        let reminderTime = earliestBedtime.addingTimeInterval(-30 * 60)
        
        // Format the times for the notification body
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        let timeStrings = bedtimes.map { formatter.string(from: $0) }
        
        // Create the body text with the 4 recommendations
        let body = "Time to start winding down. Recommended bedtimes: \(timeStrings.joined(separator: ", "))."

        let content = UNMutableNotificationContent()
        content.title = "Bedtime Reminder"
        content.body = body
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false) // Not repeating
        
        // Use a static ID to ensure only one bedtime reminder is set
        let request = UNNotificationRequest(identifier: "BEDTIME_REMINDER", content: content, trigger: trigger)
        
        // Remove any old bedtime reminders first
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["BEDTIME_REMINDER"])
        
        // Add the new one
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling bedtime reminder: \(error.localizedDescription)")
            } else {
                print("Successfully scheduled bedtime reminder for \(reminderTime)")
            }
        }
    }

    func cancelNotification(for alarm: AppAlarm) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [alarm.id])
    }
    
    // MARK: - Persistence (Using your existing service)

    func saveAlarms(_ alarms: [AppAlarm]) {
        persistenceService.save(alarms: alarms)
    }
    
    func loadAlarms() -> [AppAlarm] {
        return persistenceService.loadAlarms()
    }

    // MARK: - UNUserNotificationCenterDelegate
    
    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show the notification even when the app is active
        completionHandler([.banner, .sound, .badge])
    }
}
