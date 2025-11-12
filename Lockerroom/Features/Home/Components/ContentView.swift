//
//  ContentView.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/9/25.
//

import SwiftUI
import GameKit

struct ContentView: View {
    @EnvironmentObject private var viewModel: HomeViewModel
    
    @State private var waterDrops: [(id: UUID, offset: CGSize, scale: CGFloat, color: Color)] = []
    
    var body: some View {
        
        ZStack {
            // This uses the BrandPink from your Assets.xcassets
            Color.brandPink.ignoresSafeArea()
            
            // The main VStack now fills the whole screen,
            // and we will use internal Spacers to position content.
            VStack(spacing: 0) {
                
                // --- 1. NEW TOP HEADER (Trophy Right) ---
                HStack {
                    Spacer() // Push everything to the right
                    
                    // Challenges Button (Right) - Trophy Icon Only
                    Button(action: viewModel.challengesButtonTapped) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 5) // Adjust for safe area/top alignment
                }
                .padding(.horizontal, 20)
                
                // --- 2. NEW COMBINED HEADER (Mental | Profile | Physical) ---
                HStack(spacing: 0) {
                    // MENTAL Health Meter (Left)
                    HealthMeterView(label: "MENTAL", value: viewModel.avatar.mentalHealth, color: .cyan)
                        .frame(width: 120) // Constrain width for a compact look
                    
                    Spacer()
                    
                    // Profile Button & Info Stack (CENTERED BLOCK)
                    Button(action: viewModel.profileButtonTapped) {
                        VStack(spacing: 6) {
                            // Profile Image
                            viewModel.playerAvatarImage
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                            
                            // Player Name
                            Text(GKLocalPlayer.local.alias)
                                .font(.title3.bold())
                            
                            // Status Message (Moved to Header, Below Name)
                            Text(viewModel.avatar.statusMessage)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(5)
                        }
                        .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // PHYSICAL Health Meter (Right)
                    HealthMeterView(label: "PHYSICAL", value: viewModel.avatar.physicalHealth, color: .green)
                        .frame(width: 120) // Constrain width for a compact look
                }
                .padding(.horizontal, 20)
                .padding(.top, 15) // Space from the top trophy icon
                
                
                // --- AVATAR AND ACTION BLOCK (CENTRAL FOCUS) ---
                // This VStack will now expand to fill all available
                // space between the header and the bottom logo.
                VStack(spacing: 10) {
                    
                    Spacer() // Pushes content to the vertical center
                    
                    
                    // --- **** THIS IS THE MIGRATION **** ---
                    
                    // 3. PLAYER AVATAR (Main Hub)
                    if viewModel.hasConfiguredAvatar {
                        
                        // Use the new RealityKit view
                        RealityAvatarView(
                            state: viewModel.avatar.currentState,
                            gender: viewModel.userProfile.avatarGender,
                            backgroundColor: viewModel.isHydrating ? .blue.opacity(0.3) : .clear
                        )
                        .frame(height: 350) // Explicit, non-ambiguous height
                        .padding(.horizontal, 10)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                viewModel.isActionMenuVisible.toggle()
                            }
                        }
                        
                    } else {
                        // 2. PLACEHOLDER ---
                        Image(systemName: "figure.stand")
                            .font(.system(size: 250)) // Made icon larger
                            .frame(height: 350) // Explicit, non-ambiguous height
                            .foregroundColor(.white.opacity(0.5))
                            .onTapGesture {
                                viewModel.appIconButtonTapped()
                            }
                    }
                    // --- **** END MIGRATION **** ---
                    
                    
                    // --- 4. CONDITIONAL ACTION BUTTONS (Menu) ---
                    if viewModel.isActionMenuVisible {
                        HStack(spacing: 12) {
                            ActionButtonView(icon: "moon.zzz.fill", label: "Sleep") {
                                viewModel.isShowingSleepView = true
                            }
                            
                            ActionButtonView(icon: "drop.fill", label: "Water") {
                                viewModel.logWaterAndAnimate()
                            }
                            
                            ActionButtonView(icon: "brain.head.profile", label: "Mindfulness") {
                                viewModel.isShowingMindfulnessView = true
                            }
                            ActionButtonView(icon: "figure.run", label: "Exercise") {
                                viewModel.isShowingExerciseView = true
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 15)
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                    }
                    
                    Spacer() // Pushes content to the vertical center
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity) // This VStack expands
                .padding(.bottom, 20)
                
                
                // --- 5. LOGO AT BOTTOM (Toggles Action Menu) ---
                Button(action: {
                    viewModel.appIconButtonTapped()
                }) {
                    Image("3kappicon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80)
                        .shadow(radius: 5)
                }
                .padding(.bottom, 40)
            }
            
        }
        .animation(.spring(), value: viewModel.isHydrating)
        // Use .task to call the new async function
        .task {
            await viewModel.loadPlayerAvatar()
        }
        .sheet(isPresented: $viewModel.isShowingSleepView) {
            SleepView(onAlarmSet: { newAlarm in
                viewModel.addAlarm(newAlarm)
                viewModel.logAlarmSet()
            })
        }
        .sheet(isPresented: $viewModel.isShowingMindfulnessView) {
            MindfulnessView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $viewModel.isShowingExerciseView) {
            ExerciseView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $viewModel.isShowingProfileView) {
            ProfileView()
                .environmentObject(viewModel)
        }
    }
    
    func startWaterDropAnimation() {
        // ... (This function remains unchanged)
        let colors: [Color] = [.meterCyan, .blue, .white.opacity(0.8)]
        
        let newDrops: [(id: UUID, offset: CGSize, scale: CGFloat, color: Color)] = (0..<3).map { _ in
            (
                id: UUID(),
                offset: CGSize.zero,
                scale: 0.1,
                color: colors.randomElement()!
            )
        }
        
        waterDrops.append(contentsOf: newDrops)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeOut(duration: 0.5)) {
                self.waterDrops = self.waterDrops.map { drop in
                    var newDrop = drop
                    newDrop.scale = CGFloat.random(in: 1.0...1.5)
                    newDrop.offset = CGSize(
                        width: CGFloat.random(in: -80...80),
                        height: CGFloat.random(in: -200...(-150))
                    )
                    return newDrop
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeIn(duration: 0.4)) {
                self.waterDrops.removeAll()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(HomeViewModel())
}
