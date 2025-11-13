//
//  AvatarRealityView.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/13/25.
//

import SwiftUI
import RealityKit

struct AvatarRealityView: View {
    @EnvironmentObject var stateManager: AvatarStateManager
    @StateObject private var controller = AvatarAnimationController()
    
    var body: some View {
        // This is the WWDC 2025 best practice
        RealityView { content in
            // MAKE (runs once)
            // 1. Load the Scene
            if let scene = try? await Entity(named: "LockerRoomScene") {
                content.add(scene)
                
                // 2. Setup the controller
                await controller.setup(with: scene)
                
                // 3. Subscribe the "Rig" to the "Brain"
                await controller.subscribe(to: stateManager)
                
                print("✅ RealityKit Scene Loaded Successfully")
            } else {
                print("❌ Failed to load 'LockerRoomScene.reality'.")
            }
        } update: { content in
            // UPDATE (runs when @Published properties change)
            // This handles the "Persistent State" animations
            print("RealityView Update: Mood changed to \(controller.currentMood)")
            Task {
                await controller.playPersistentAnimation(for: controller.currentMood)
            }
        }
        .edgesIgnoringSafeArea(.all)
        
        // This handles the "One-Shot Action" animations
        .onChange(of: stateManager.athleteState.lastWaterTime) {
            Task { await controller.playOneShotAnimation(named: "Drink_Water") }
        }
        .onChange(of: stateManager.athleteState.lastMindfulnessTime) {
            Task { await controller.playOneShotAnimation(named: "Meditate_OneShot") }
        }
        .onChange(of: stateManager.athleteState.lastWorkoutTime) {
            Task { await controller.playOneShotAnimation(named: "Train_OneShot") }
        }
        // TODO: Add one-shot for "Set Alarm" button
    }
}

// Preview Provider
struct AvatarRealityView_Previews: PreviewProvider {
    static var previews: some View {
        AvatarRealityView()
            .environmentObject(AvatarStateManager(persistenceService: PersistenceService()))
    }
}
