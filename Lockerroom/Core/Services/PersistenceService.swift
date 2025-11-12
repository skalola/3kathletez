//
//  PersistenceService.swift
//  Locker Room
//
//  Created by Shiv Kalola on 11/9/25.
//

import Foundation

// This service will manage saving/loading data from UserDefaults
struct PersistenceService {
    
    private let userProfileKey = "3KUserProfile"
    
    func saveProfile(_ profile: UserProfile) {
        // We will use JSONEncoder to save the struct
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: userProfileKey)
            print("Profile saved.")
        }
    }
    
    func loadProfile() -> UserProfile {
        if let data = UserDefaults.standard.data(forKey: userProfileKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            print("Profile loaded.")
            return profile
        }
        // No profile saved, return a new one
        print("No profile found, returning new profile.")
        return UserProfile()
    }
}
