//
//  NativeAvatarView.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/11/25.
//
//  This view is now a "dumb" view. It gets all its assets
//  from the AvatarService and just displays them.
//
//  This version adds robust lighting and camera setup
//  and cleans up console log spam.
//

import SwiftUI
import SceneKit
import Combine
import ModelIO // <-- **** THIS IS THE FIX ****

struct NativeAvatarView: UIViewRepresentable {
    
    @EnvironmentObject var avatarService: AvatarService
    
    let state: Avatar.State
    let gender: String
    var backgroundColor: Color = .clear
    
    private let scnView = SCNView()
    
    func makeUIView(context: Context) -> SCNView {
        scnView.scene = SCNScene()
        scnView.backgroundColor = UIColor(backgroundColor)
        
        // 1. Add a camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0.8, z: 2.5) // Default position
        scnView.scene?.rootNode.addChildNode(cameraNode)
        scnView.pointOfView = cameraNode // Make this the active camera
        
        // 2. Add an ambient light (fills the scene)
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light!.type = .ambient
        ambientLight.light!.intensity = 400 // Soft fill light
        scnView.scene?.rootNode.addChildNode(ambientLight)
        
        // 3. Add a key light (creates shadows, gives depth)
        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light!.type = .omni
        keyLight.light!.intensity = 1500 // Bright main light
        keyLight.position = SCNVector3(x: 1, y: 2, z: 3)
        scnView.scene?.rootNode.addChildNode(keyLight)

        scnView.allowsCameraControl = true
        
        // Pass the SCNView and Service to the coordinator
        context.coordinator.setup(view: scnView, service: avatarService)
        
        // If the service already has the model, add it.
        if let node = avatarService.avatarNode {
            context.coordinator.setAvatarNode(node)
        }
        
        return scnView
    }
    
    func updateUIView(_ scnView: SCNView, context: Context) {
        
        // We only update the animation IF the state has changed.
        guard state != context.coordinator.currentState else {
            return
        }
        context.coordinator.currentState = state
        
        // Get the filename for the current state
        let animationName = state.getAnimationFileName(for: gender)
        
        // Tell the Coordinator to get the PRE-LOADED animation
        if let animPlayer = avatarService.getAnimation(named: animationName) {
            context.coordinator.playAnimation(animPlayer, forKey: animationName)
        } else {
            // Fallback: try to play "Idle" if the animation wasn't found
            // We use "neutral" to get a generic idle animation.
            let idleName = Avatar.State.idle.getAnimationFileName(for: "neutral")
            if let idlePlayer = avatarService.getAnimation(named: idleName) {
                context.coordinator.playAnimation(idlePlayer, forKey: idleName)
            }
        }
        
        // Update background color (for .drinking state)
        scnView.backgroundColor = UIColor(backgroundColor)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    // --- Coordinator ---
    class Coordinator: NSObject {
        weak var scnView: SCNView?
        private var avatarNode: SCNNode?
        private var currentAnimationKey: String = ""
        private var avatarNodeSubscriber: AnyCancellable?
        
        var currentState: Avatar.State = .idle
        
        /// Sets up the coordinator and subscribes to the AvatarService
        func setup(view: SCNView, service: AvatarService) {
            self.scnView = view
            
            // Subscribe to the $avatarNode publisher
            self.avatarNodeSubscriber = service.$avatarNode
                .receive(on: RunLoop.main) // Ensure we're on the main thread
                .sink { [weak self] newNode in
                    // We no longer print here, this can be noisy
                    self?.setAvatarNode(newNode)
                }
        }
        
        /// Adds the new avatar model to the scene
        func setAvatarNode(_ node: SCNNode?) {
            guard let scnView = scnView, let cameraNode = scnView.pointOfView else { return }
            
            // Remove the old avatar
            avatarNode?.removeFromParentNode()
            avatarNode = nil
            
            guard let node = node else {
                print("Coordinator: setAvatarNode received nil, clearing scene.")
                return
            }
            
            // Add the new avatar
            self.avatarNode = node
            scnView.scene?.rootNode.addChildNode(node)
            print("Coordinator: New avatar node added to scene.")
            
            // Auto-frame the camera on the new node
            let (min, max) = node.boundingBox
            let center = SCNVector3((min.x + max.x) / 2, (min.y + max.y) / 2, (min.z + max.z) / 2)
            let maxDimension = Swift.max(max.x - min.x, max.y - min.y, max.z - min.z)
            let cameraDistance = Float(maxDimension) * 1.5 // Adjust 1.5 to zoom in/out
            cameraNode.position = SCNVector3(center.x, center.y + 0.2, center.z + cameraDistance)
            cameraNode.look(at: center)
        }
        
        /// Plays a pre-loaded animation
        func playAnimation(_ animPlayer: SCNAnimationPlayer, forKey key: String) {
            guard let avatarNode = avatarNode else { return }
            
            if key == currentAnimationKey { return }
            
            avatarNode.removeAllAnimations()
            avatarNode.addAnimationPlayer(animPlayer, forKey: key)
            currentAnimationKey = key
            
            print("Coordinator: Applying animation '\(key)'")
        }
    }
}
