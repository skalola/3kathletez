//
//  RealityAvatarView.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/12/25.
//
//  [MIGRATION TO REALITYKIT]
//  This is a pure SwiftUI view using 'RealityView'.
//  It replaces 'NativeAvatarView.swift' (which was a UIViewRepresentable).
//

import SwiftUI
import RealityKit
import Combine

struct RealityAvatarView: View {
    
    @EnvironmentObject var avatarService: AvatarService
    
    let state: Avatar.State
    let gender: String
    var backgroundColor: Color = .clear
    
    // Store the current animation state to prevent re-playing
    @State private var currentAnimationKey: String = ""
    @State private var entitySubscriber: AnyCancellable?
    
    var body: some View {
        
        // RealityView is the modern replacement for SCNView/ARView in SwiftUI
        RealityView { content in
            // This closure is called ONCE when the view appears.
            // We set up the static parts of the scene here.
            
            // 1. Add default lighting
            // RealityKit doesn't add lights by default in a non-AR view.
            // This is a simple setup similar to your old one.
            let ambientLight = AmbientLight(color: .white)
            content.add(ambientLight)
            ambientLight.light?.intensity = 400
            
            let keyLightEntity = Entity()
            let directionalLight = DirectionalLight(color: .white, intensity: 1500, isMeteorological: true)
            keyLightEntity.components.set(directionalLight)
            keyLightEntity.setPosition([1, 2, 3], relativeTo: nil)
            keyLightEntity.look(at: [0, 0, 0], from: [1, 2, 3], relativeTo: nil)
            content.add(keyLightEntity)
            
            // 2. Add a camera
            // We need to manually add and position a camera
            let cameraEntity = PerspectiveCamera()
            cameraEntity.name = "avatar_camera"
            cameraEntity.camera.fieldOfViewInDegrees = 60
            cameraEntity.setPosition([0, 0.8, 2.5], relativeTo: nil) // Your old default position
            content.add(cameraEntity)
            
            // 3. Add the avatar entity IF it's already loaded
            if let entity = avatarService.avatarEntity {
                addEntityToScene(entity, content: &content)
            }
            
        } update: { content in
            // This 'update' closure is called when SwiftUI state changes,
            // including 'state' or 'avatarService.avatarEntity'.
            
            // 1. Find our entity in the scene
            guard let entity = content.entities.first(where: { $0.name == "avatar_entity" }),
                  let camera = content.entities.first(where: { $0.name == "avatar_camera" })
            else {
                // If the entity isn't loaded yet, do nothing
                // This will re-run when 'avatarService.avatarEntity' is published
                return
            }

            // 2. Auto-frame the camera
            // This logic is adapted from your old coordinator
            let bounds = entity.visualBounds(relativeTo: nil)
            let center = bounds.center
            let maxDimension = max(bounds.extents.x, bounds.extents.y, bounds.extents.z)
            
            // Ensure maxDimension is a sane value
            guard maxDimension > 0.01 else { return }
            
            let cameraDistance = Float(maxDimension) * 1.5
            camera.position = [center.x, center.y + 0.2, center.z + cameraDistance]
            camera.look(at: center, from: camera.position, relativeTo: nil)
            
            // 3. Play the requested animation
            let animationName = state.getAnimationFileName(for: gender)
            
            // Only update animation if the name is new
            guard animationName != currentAnimationKey else {
                return
            }
            currentAnimationKey = animationName
            
            // Stop all previous animations
            entity.stopAllAnimations(transitionDuration: 0.2) // Smooth transition
            
            if let animResource = avatarService.getAnimation(named: animationName) {
                // Play the new animation, looping it
                print("RealityView: Playing animation '\(animationName)'")
                entity.playAnimation(animResource.repeat(), transitionDuration: 0.2, startsPaused: false)
            } else {
                // Fallback to idle
                let idleName = Avatar.State.idle.getAnimationFileName(for: "neutral")
                if let idleResource = avatarService.getAnimation(named: idleName) {
                    print("RealityView: Animation not found, playing idle.")
                    entity.playAnimation(idleResource.repeat(), transitionDuration: 0.2, startsPaused: false)
                } else {
                    print("RealityView: CRITICAL - No animation and no idle animation found.")
                }
            }
            
        }
        .background(backgroundColor) // Handle background color
        .onAppear {
            // Subscribe to the service's publisher
            // This is needed if the view appears BEFORE the entity has finished loading
            self.entitySubscriber = avatarService.$avatarEntity
                .receive(on: RunLoop.main)
                .sink { newEntity in
                    // This will trigger the 'update' closure
                    // We just need to observe it, 'update' handles the logic
                    if newEntity != nil {
                        print("RealityAvatarView: Observed new entity from service.")
                    }
                }
        }
    }
    
    /// Helper to add the entity to the scene
    private func addEntityToScene(_ entity: Entity, content: inout RealityViewContent) {
        // Give it a name so we can find it in the 'update' closure
        entity.name = "avatar_entity"
        content.add(entity)
        print("RealityAvatarView: 'make' closure added entity to scene.")
    }
}
