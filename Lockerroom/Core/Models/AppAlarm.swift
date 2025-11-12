//
//  AppAlarm.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/9/25.
//

import Foundation

// This enum now lives cleanly inside the
// only model that uses it.
enum AlarmRepeatFrequency: String, Codable, CaseIterable, Hashable {
    case once = "Once"
    case daily = "Daily"
    case weekly = "Weekly"
}

// This is the clean, simple model just for sleep alarms.
struct AppAlarm: Codable, Identifiable, Equatable {
    let id: UUID
    var wakeUpTime: Date
    var bedTimes: [Date]
    var notificationIDs: [String]
    var isEnabled: Bool
    var repeatFrequency: AlarmRepeatFrequency
    var soundName: String
    
    init(wakeUpTime: Date, bedTimes: [Date], repeatFrequency: AlarmRepeatFrequency, soundName: String) {
        self.id = UUID()
        self.wakeUpTime = wakeUpTime
        self.bedTimes = bedTimes
        self.notificationIDs = []
        self.isEnabled = true
        self.repeatFrequency = repeatFrequency
        self.soundName = soundName
    }
}
