//
//  PersistenceService.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/9/25.
//

import Foundation
import CoreData
import SwiftUI // Import SwiftUI

class PersistenceService {
    
    // ---
    // *** FIX: Added 'isMock' and the required init ***
    // ---
    let isMock: Bool
    
    init(isMock: Bool = false) {
        self.isMock = isMock
        // We can skip loading the container if this is just a mock
        if !isMock {
            _ = persistentContainer
        }
    }
    // --- End Fix ---

    // Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
// ... (existing code) ...
        let container = NSPersistentContainer(name: "Lockerroom")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
// ... (existing code) ...
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    private var viewContext: NSManagedObjectContext {
// ... (existing code) ...
        return persistentContainer.viewContext
    }

    // MARK: - Core Data Saving support
    func saveContext () {
// ... (existing code) ...
        if viewContext.hasChanges {
            do {
                // *** FIX: Corrected typo 'viewHContext' to 'viewContext' ***
                try viewContext.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - UserProfile CoreData Functions
    
    func save(profile: UserProfile) {
// ... (existing code) ...
        let data = try? JSONEncoder().encode(profile)
        UserDefaults.standard.set(data, forKey: "userProfile")
    }

    func loadProfile() -> UserProfile? {
// ... (existing code) ...
        guard let data = UserDefaults.standard.data(forKey: "userProfile") else {
            return nil
        }
        return try? JSONDecoder().decode(UserProfile.self, from: data)
    }

    // MARK: - LoggedActivity CoreData Functions
    
    func save(activity: LoggedActivity) {
// ... (existing code) ...
    }

    func loadActivities() -> [LoggedActivity] {
// ... (existing code) ...
        return [] // Placeholder
    }
    
    // MARK: - AthleteState Persistence (Codable to UserDefaults)
    
    /// Saves the AthleteState
    func save(athleteState: AthleteState) {
// ... (existing code) ...
        if isMock { return } // Don't save if we are a mock service
        do {
            let data = try JSONEncoder().encode(athleteState)
            UserDefaults.standard.set(data, forKey: "athleteState")
        } catch {
            print("Failed to save AthleteState: \(error.localizedDescription)")
        }
    }

    /// Loads the AthleteState
    func loadAthleteState() -> AthleteState? {
// ... (existing code) ...
        if isMock { return nil } // Don't load if we are a mock service
        guard let data = UserDefaults.standard.data(forKey: "athleteState") else {
            return nil
        }
        do {
            return try JSONDecoder().decode(AthleteState.self, from: data)
        } catch {
            print("Failed to load AthleteState: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Alarm Persistence
    
    /// Saves all alarms
    func save(alarms: [AppAlarm]) {
// ... (existing code) ...
        if isMock { return }
        do {
            let data = try JSONEncoder().encode(alarms)
            UserDefaults.standard.set(data, forKey: "appAlarms")
        } catch {
            print("Failed to save alarms: \(error.localizedDescription)")
        }
    }
    
    /// Loads all alarms
    func loadAlarms() -> [AppAlarm] {
// ... (existing code) ...
        if isMock { return [] }
        guard let data = UserDefaults.standard.data(forKey: "appAlarms") else {
            return []
        }
        do {
            return try JSONDecoder().decode([AppAlarm].self, from: data)
        } catch {
            print("Failed to load alarms: \(error.localizedDescription)")
            return []
        }
    }
    
    // *** FIX: Removed Apple User ID functions ***
}
