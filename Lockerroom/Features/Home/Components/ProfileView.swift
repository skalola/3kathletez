//
//  ProfileView.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/10/25.
//

import SwiftUI
import GameKit
import HealthKit

struct ProfileView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var totalSteps: Int = 0
    @State private var lastWorkoutDate: String = "N/A"
    
    // --- UPDATED: State for Avatar ID Input ---
    @State private var avatarIdInput: String = ""
    private let rpmCreatorURL = URL(string: "https://3k-athletez.readyplayer.me/avatar")!

    var body: some View {
        NavigationView {
            ZStack {
                Color.blue.opacity(0.8).ignoresSafeArea()
                
                List {
                    profileHeader
                    readyPlayerMeSection // --- UPDATED SECTION ---
                    healthMetersSection
                    gameCenterSection
                    healthKitSection
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Athlete Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        // --- SAVE AVATAR ID WHEN DONE ---
                        homeViewModel.saveAvatar(id: avatarIdInput)
                        dismiss()
                    }
                }
            }
            .onAppear {
                // --- LOAD INITIAL ID ---
                // We parse the ID from the saved URL
                let fullUrl = homeViewModel.userProfile.avatarURL
                if !fullUrl.isEmpty, let id = fullUrl.split(separator: "/").last?.split(separator: ".").first {
                    self.avatarIdInput = String(id)
                }
                simulateHealthKitData()
            }
        }
    }
    
    // MARK: - Helper Sections
    
    private var profileHeader: some View {
        Section {
            HStack {
                // --- FIX: Use the ViewModel's loaded Game Center Image ---
                homeViewModel.playerAvatarImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .cornerRadius(10)
                
                VStack(alignment: .leading) {
                    Text(GKLocalPlayer.local.alias)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text("Weight: \(Int(homeViewModel.userProfile.weightInLbs)) lbs")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
        }
        .listRowBackground(Color.brandPink.opacity(0.5))
    }
    
    // --- UPDATED SECTION FOR READY PLAYER ME ---
    private var readyPlayerMeSection: some View {
        Section("Ready Player Me Avatar") {
            VStack(alignment: .leading, spacing: 12) {
                // 1. Link to open the creator in Safari
                Link(destination: rpmCreatorURL) {
                    HStack {
                        Text("Open Avatar Creator in Safari")
                        Spacer()
                        Image(systemName: "safari.fill")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                
                // 2. Text field for the ID
                Text("After creating, paste your Avatar ID here:")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                TextField("Paste Avatar ID...", text: $avatarIdInput)
                    .foregroundColor(.white)
                    .keyboardType(.default)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            .padding(.vertical, 5)
        }
        .listRowBackground(Color.brandPink.opacity(0.3))
    }
    // --- END UPDATED SECTION ---
    
    private var healthMetersSection: some View {
        Section("Current Status") {
            HealthMeterView(label: "MENTAL", value: homeViewModel.avatar.mentalHealth, color: .cyan)
            HealthMeterView(label: "PHYSICAL", value: homeViewModel.avatar.physicalHealth, color: .green)
        }
        .listRowBackground(Color.brandPink.opacity(0.3))
    }
    
    private var gameCenterSection: some View {
        Section("Game Center Leaderboard") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "figure.walk.circle.fill")
                        .foregroundColor(.green)
                    Text("Total Exercise Minutes")
                    Spacer()
                    Text("4,200 min") // Placeholder
                        .foregroundColor(.white)
                }
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("Achievements Unlocked")
                    Spacer()
                    Text("4 / 12") // Placeholder
                        .foregroundColor(.white)
                }
            }
        }
        .listRowBackground(Color.brandPink.opacity(0.3))
    }
    
    private var healthKitSection: some View {
        Section("Health Data (Simulated)") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("Total Steps Today")
                    Spacer()
                    Text("\(totalSteps)")
                        .foregroundColor(.white)
                }
                HStack {
                    Image(systemName: "heart.text.square.fill")
                        .foregroundColor(.red)
                    Text("Last Workout")
                    Spacer()
                    Text(lastWorkoutDate)
                        .foregroundColor(.white)
                }
            }
        }
        .listRowBackground(Color.brandPink.opacity(0.3))
    }
    
    // MARK: - HealthKit Simulation
    
    private func simulateHealthKitData() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.totalSteps = Int.random(in: 4000...12000)
            self.lastWorkoutDate = Date().formatted(date: .abbreviated, time: .omitted)
        }
    }
}
