//
//  AvatarService.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/11/25.
//
//  [MIGRATION TO REALITYKIT]
//  This service now loads USDZ assets and caches RealityKit 'AnimationResources'.
//  It publishes a RealityKit 'Entity' for RealityView to consume.
//

import Foundation
import RealityKit // <-- Import RealityKit
import Combine

class AvatarService: ObservableObject {
    
    // Singleton pattern
    static let shared = AvatarService()
    
    // 1. Published Properties
    @Published var avatarEntity: Entity? // <-- Changed from SCNNode
    
    // 2. Caches
    // Cache 'AnimationResource' instead of 'SCNAnimationPlayer'
    private var animationCache: [String: AnimationResource] = [:]
    
    // 3. Private properties
    private var modelCachingURL: URL? {
        guard let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        // IMPORTANT: Assumes you have converted your model to .usdz
        return docsURL.appendingPathComponent("avatar.usdz")
    }
    
    private init() {
        // Start preloading animations in an async task
        Task {
            await preloadLocalAnimations()
        }
    }
    
    // MARK: - Public API
    
    /// Asynchronously downloads (or loads from cache) the main avatar model.
    /// Note: This now uses async/await.
    func loadAvatar(from url: URL) async { // <-- Make async
        
        // 1. Check if we have a cached file
        if let modelURL = modelCachingURL, FileManager.default.fileExists(atPath: modelURL.path) {
            await loadSceneFromLocalURL(modelURL)
            return
        }
        
        // 2. If not, download it using new async URLSession
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                print("AvatarService: Failed to download avatar: HTTP Status \((response as? HTTPURLResponse)?.statusCode ?? 0).")
                return
            }
            
            // 3. Save to permanent cache
            guard let modelURL = self.modelCachingURL else {
                print("AvatarService: Could not get documents directory to cache model.")
                return
            }
            
            try data.write(to: modelURL, options: .atomic)
            print("AvatarService: Model saved to permanent cache.")
            
            // 4. Load the newly cached file
            await self.loadSceneFromLocalURL(modelURL)
            
        } catch {
            print("AvatarService: Failed to download or save model: \(error)")
        }
    }
    
    /// Retrieves a pre-loaded animation resource from the memory cache.
    func getAnimation(named filename: String) -> AnimationResource? { // <-- Return AnimationResource
        if let animation = animationCache[filename] {
            return animation
        }
        return nil
    }
    
    // MARK: - Private Asset Loading
    
    /// Recursively finds and pre-loads all .usdz files from the app bundle.
    private func preloadLocalAnimations() async { // <-- Make async
        var animationFiles: [URL] = []
        let fileManager = FileManager.default
        let bundleURL = Bundle.main.bundleURL

        guard let enumerator = fileManager.enumerator(at: bundleURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
             print("AvatarService: CRITICAL - Failed to create bundle enumerator.")
             return
        }

        // Find all .usdz files (assuming you converted them from .glb)
        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "usdz" { // <-- Look for usdz
                animationFiles.append(fileURL)
            }
        }
        
        if animationFiles.isEmpty {
            print("AvatarService: CRITICAL - No .usdz animation files found. Make sure assets were converted.")
            return
        }
        
        var count = 0
        for fileURL in animationFiles {
            let filename = fileURL.deletingPathExtension().lastPathComponent
            
            // Skip the main model file
            if filename == "avatar" || filename == "model" || filename == "Feminine_TPose" || filename == "Masculine_TPose" {
                continue
            }
            
            if animationCache[filename] == nil {
                // Await the new async loading function
                if let animResource = await loadAnimationResource(from: fileURL) {
                    animationCache[filename] = animResource
                    count += 1
                }
            }
        }
        print("AvatarService: Pre-loaded \(count) animations into memory cache.")
    }
    
    
    /// Loads a single .usdz file and extracts its AnimationResource.
    private func loadAnimationResource(from fileURL: URL) async -> AnimationResource? {
        do {
            // 1. Load the entity from the .usdz file
            // 'loadAsync' is lightweight and doesn't load all mesh data
            let animEntity = try await Entity.loadAsync(contentsOf: fileURL).value
            
            // 2. Extract the first available animation
            // USDZ files contain their animations.
            if let animation = animEntity.availableAnimations.first {
                return animation
            } else {
                print("AvatarService: No animation found in \(fileURL.lastPathComponent)")
                return nil
            }
        } catch {
            print("AvatarService: Failed to load animation from \(fileURL.lastPathComponent): \(error)")
            return nil
        }
    }
    
    /// Loads the main avatar model and publishes the entity.
    private func loadSceneFromLocalURL(_ fileURL: URL) async { // <-- Make async
        do {
            // 1. Load the main entity asynchronously
            // 'load' or 'loadAsync' works here. 'load' is simpler if you need the entity right away.
            let entity = try await Entity.load(contentsOf: fileURL)
            
            // 2. Ensure the entity has a collision shape for gestures (tapping)
            // This is crucial for the TapGesture in RealityView to work.
            entity.generateCollisionShapes(recursive: true)
            
            // 3. Publish on main thread
            await MainActor.run {
                self.avatarEntity = entity
                print("AvatarService: Model loaded from cache and published.")
            }
        } catch {
            print("AvatarService: Failed to load scene from data (RealityKit): \(error)")
        }
    }
}
