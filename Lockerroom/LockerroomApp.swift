//
//  LockerroomApp.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/9/25.
//
import SwiftUI

@main
struct LockerroomApp: App {
    
    // *** NEW: State to manage the launch screen ***
    @State private var isAppReady: Bool = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Show ContentView *underneath*
                ContentView()
                    .preferredColorScheme(.dark)
                
                // Show LaunchView *on top*
                if !isAppReady {
                    LaunchView(isAppReady: $isAppReady)
                        .transition(.opacity.animation(.easeOut(duration: 0.5)))
                }
            }
        }
    }
}
