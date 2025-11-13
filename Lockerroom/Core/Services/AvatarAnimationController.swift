//
//  AvatarAnimationController.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/13/25.
//
import RealityKit
import Foundation
import Combine // Import Combine

/// Manages the 3D avatar, finding animations in the scene, and playing them.
/// *** FIX: Conforms to ObservableObject as requested ***
@MainActor
class AvatarAnimationController: ObservableObject {
    
    // MARK: - Published State
    
    /// This is the "Persistent State" (e.g., "Idle", "Sleeping").
    /// The RealityView will observe this property.
    @Published private(set) var currentMood: AthleteState.Mood = .neutral
    
    // MARK: - Private Properties
    
    private var rootEntity: Entity?
    private var characterEntity: Entity?
    private var stateSubscriber: AnyCancellable?
    
    // Cache animations so we don't search the tree every time
    private var animationResourceCache: [String: AnimationResource] = [:]

    // MARK: - Setup
    
    /// Called when the RealityView's `make` closure runs.
    func setup(with entity: Entity) {
        self.rootEntity = entity
        
        // Find the character entity, assuming it's named "Avatar" in Reality Composer Pro
        self.characterEntity = entity.findEntity(named: "Avatar") ?? entity
        
        // Pre-load all available animations from the scene file
        print("AvatarAnimationController: Pre-caching animations...")
        for anim in characterEntity?.availableAnimations ?? [] {
            if let name = anim.name {
                print("   - Found: \(name)")
                animationResourceCache[name] = anim
            }
        }
        
        // Start Idle by default
        playPersistentAnimation(named: "Idle", loop: true)
    }

    /// Connects this "Rig" to the app's "Brain" (AvatarStateManager).
    func subscribe(to stateManager: AvatarStateManager) {
        // This subscriber updates our @Published property
        stateSubscriber = stateManager.$athleteState
            .map { $0.mood }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newMood in
                self?.currentMood = newMood
            }
    }
    
    // MARK: - Animation Players
    
    /// Plays a "Persistent" animation (like an idle or sleep loop) based on state.
    /// This is called by the RealityView's `update` closure.
    func playPersistentAnimation(for mood: AthleteState.Mood) {
        switch mood {
        case .neutral, .happy, .energized:
            playPersistentAnimation(named: "Idle", loop: true)
        case .sad:
            playPersistentAnimation(named: "Sad_Idle", loop: true)
        case .tired:
            playPersistentAnimation(named: "Tired_Idle", loop: true)
        case .thirsty:
            playPersistentAnimation(named: "Thirsty_Idle", loop: true)
        case .sleeping:
            playPersistentAnimation(named: "Sleep", loop: true)
        }
    }

    /// Plays a "One-Shot" animation (like drinking or setting an alarm)
    /// that does not loop and returns to the current persistent state.
    func playOneShotAnimation(named name: String) {
        guard let entity = characterEntity,
              let animation = animationResourceCache[name] else {
            print("⚠️ OneShot Animation '\(name)' not found.")
            return
        }
        
        // 1. Play the one-shot animation
        entity.playAnimation(animation, transitionDuration: 0.25, startsPaused: false)
        
        // 2. After it finishes, return to the *current persistent mood animation*
        
        // *** FIX for Error 1: Use .definition.duration ***
        let duration = animation.definition.duration ?? 3.0 // Default to 3s
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            // Re-apply the persistent state animation
            self.playPersistentAnimation(for: self.currentMood)
        }
    }
    
    /// Private helper to play and cache the looping animation
    private func playPersistentAnimation(named name: String, loop: Bool = false) {
        guard let entity = characterEntity,
              let animation = animationResourceCache[name] else {
            print("⚠️ Persistent Animation '\(name)' not found.")
            return
        }
        
        if loop {
            entity.playAnimation(animation.repeat(), transitionDuration: 0.5, startsPaused: false)
        } else {
            entity.playAnimation(animation, transitionDuration: 0.5, startsPaused: false)
        }
    }
}
