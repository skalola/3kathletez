//
//  LoggedActivity.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/9/25.
//

import Foundation

// A model for the Exercise log
struct LoggedActivity: Identifiable, Codable {
    // These are stored properties
    let id: UUID
    let name: String
    let icon: String // SF Symbol name
    let minutes: Int // <-- Changed to 'minutes' for simple logging
    let date: Date

    // We use a custom initializer to assign the UUID automatically.
    init(name: String, icon: String, minutes: Int, date: Date) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.minutes = minutes
        self.date = date
    }
    
    // This computed property is what Game Center uses.
    var minutesLogged: Int {
        return minutes
    }
}
