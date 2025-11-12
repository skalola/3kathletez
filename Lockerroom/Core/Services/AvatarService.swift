//
//  AvatarService.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/11/25.
//
//  This is a singleton service that manages all 3D asset loading and caching.
//  1. It pre-loads all local animations from the bundle into a memory cache.
//  2. It downloads the main avatar .glb and caches it permanently in the Documents directory.
//  3. It publishes the loaded avatar node for any view to observe.
//

import Foundation
import SceneKit
import ModelIO
import Combine
import SceneKit.ModelIO // <-- This import is correct

class AvatarService: ObservableObject {
    
    // Singleton pattern
    static let shared = AvatarService()
    
    // 1. Published Properties
    @Published var avatarNode: SCNNode?
    
    // 2. Caches
    private var animationCache: [String: SCNAnimationPlayer] = [:]
    
    // 3. Private properties
    private var modelCachingURL: URL? {
        guard let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return docsURL.appendingPathComponent("avatar.glb")
    }
    
    // When the service is created, it immediately pre-loads all animations
    private init() {
        preloadLocalAnimations()
    }
    
    // MARK: - Public API
    
    /// Asynchronously downloads (or loads from cache) the main avatar model.
    func loadAvatar(from url: URL) {
        
        // 1. Check if we have a cached file
        if let modelURL = modelCachingURL, FileManager.default.fileExists(atPath: modelURL.path) {
            loadSceneFromLocalURL(modelURL)
            return
        }
        
        // 2. If not, download it
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("AvatarService: Failed to download avatar model: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                print("AvatarService: Failed to download avatar: HTTP Status \(httpResponse.statusCode).")
                return
            }
            
            // 3. Save to permanent cache
            guard let modelURL = self.modelCachingURL else {
                print("AvatarService: Could not get documents directory to cache model.")
                return
            }
            
            do {
                try data.write(to: modelURL, options: .atomic)
                print("AvatarService: Model saved to permanent cache.")
                // 4. Load the newly cached file
                self.loadSceneFromLocalURL(modelURL)
            } catch {
                print("AvatarService: Failed to write model to cache: \(error)")
            }
        }.resume()
    }
    
    /// Retrieves a pre-loaded animation player from the memory cache.
    func getAnimation(named filename: String) -> SCNAnimationPlayer? {
        if let animation = animationCache[filename] {
            return animation
        }
        
        // We no longer print a "not found" error, as it's spammy and we have fallbacks.
        return nil
    }
    
    // MARK: - Private Asset Loading
    
    
    /// Recursively finds and pre-loads all .glb files from the app bundle into memory.
    private func preloadLocalAnimations() {
        var animationFiles: [URL] = []
        let fileManager = FileManager.default
        let bundleURL = Bundle.main.bundleURL

        // Create an enumerator to recursively search the entire app bundle
        guard let enumerator = fileManager.enumerator(at: bundleURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
             print("AvatarService: CRITICAL - Failed to create bundle enumerator.")
             return
        }

        // Find all .glb files, no matter where they are
        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "glb" {
                animationFiles.append(fileURL)
            }
        }
        
        
        if animationFiles.isEmpty {
            print("AvatarService: CRITICAL - No .glb animation files found anywhere in the app bundle.")
            return
        }
        
        var count = 0
        for fileURL in animationFiles {
            let filename = fileURL.deletingPathExtension().lastPathComponent
            
            if filename == "avatar" || filename == "model" {
                continue
            }
            
            if animationCache[filename] == nil {
                if let animPlayer = loadAnimationPlayer(from: fileURL) {
                    animationCache[filename] = animPlayer
                    count += 1
                }
            }
        }
        print("AvatarService: Pre-loaded \(count) animations into memory cache.")
    }
    
    
    /// Loads a single .glb file and extracts its SCNAnimationPlayer using a robust extraction method.
    private func loadAnimationPlayer(from fileURL: URL) -> SCNAnimationPlayer? {
        do {
            // 1. Create a ModelIO Asset from the URL
            let asset = MDLAsset(url: fileURL)
            
            // --- **** THIS IS THE FINAL ROBUST FIX **** ---
            
            // 2. Check the animation container's count
            // We cast to NSArray to safely access the .count property
            guard let animations = asset.animations as? NSArray, animations.count > 0 else {
                return nil
            }

            // 3. Get the first animation object
            // We safely get it as a generic MDLObject
            guard let mdlAnimation = animations[0] as? MDLObject else {
                return nil
            }
            
            // 4. Convert the MDLObject directly into a SceneKit SCNAnimation
            let scnAnimation = SCNAnimation(mdlObject: mdlAnimation)
            
            // --- **** END FIX **** ---

            // 5. Create the player
            let animPlayer = SCNAnimationPlayer(animation: scnAnimation)
            return animPlayer

        } catch {
            // This catch block handles the MDLAsset(url:) failing
            return nil
        }
    }
    
    /// Loads the main avatar model using ModelIO and publishes the node.
    private func loadSceneFromLocalURL(_ fileURL: URL) {
        do {
            // 1. Create a ModelIO Asset from the URL
            let asset = MDLAsset(url: fileURL)
            asset.loadTextures()

            // 2. Create a SceneKit scene from the ModelIO asset
            let scene = SCNScene(mdlAsset: asset)
            
            // 3. Find the main node
            var mainNode: SCNNode?
            scene.rootNode.enumerateChildNodes { (child, _) in
                if child.skinner != nil { mainNode = child }
            }
            if mainNode == nil {
                mainNode = scene.rootNode.childNodes.first { $0.geometry != nil }
            }
            
            let finalNode = mainNode ?? scene.rootNode
            
            // 4. Publish on main thread
            DispatchQueue.main.async {
                self.avatarNode = finalNode
                print("AvatarService: Model loaded from cache and published.")
            }
        } catch {
            print("AvatarService: Failed to load scene from data (ModelIO): \(error)")
        }
    }
}
