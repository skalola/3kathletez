//
//  AppAlarm.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/13/25.
//
import Foundation

/// This is the correct, simple alarm model.
/// The "smartness" is in *calculating* the `time`, not storing extra properties.
struct AppAlarm: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    
    /// The final, calculated wake-up time.
    var time: Date
    
    /// Whether the alarm is enabled.
    var isEnabled: Bool
    
    /// A user-facing label, e.g., "Weekday Alarm".
    var label: String = "Alarm"
}
