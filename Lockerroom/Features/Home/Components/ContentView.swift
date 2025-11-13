//
//  ContentView.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/13/25.
//
import SwiftUI
import RealityKit

struct ContentView: View {
    @StateObject private var viewModel: HomeViewModel
    @StateObject private var stateManager: AvatarStateManager // Own the stateManager
    
    @ObservedObject private var gameCenterManager = GameCenterManager.shared

    // Overload for preview provider
    init(viewModel: HomeViewModel) {
        _stateManager = StateObject(wrappedValue: viewModel.stateManager)
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // Main app initializer
    init() {
        let persistence = PersistenceService()
        let stateManager = AvatarStateManager(persistenceService: persistence)
        let homeVM = HomeViewModel(stateManager: stateManager)
        
        _stateManager = StateObject(wrappedValue: stateManager)
        _viewModel = StateObject(wrappedValue: homeVM)
    }

    var body: some View {
        ZStack {
            // 1. Background: RealityKit View
            AvatarRealityView()
                .ignoresSafeArea()
            
            // 2. Foreground: Your SwiftUI Interface
            VStack(spacing: 0) {
                HStack {
                    ProfileView(
                        name: viewModel.userName,
                        level: viewModel.userLevel,
                        image: viewModel.userImage
                    )
                    .onTapGesture {
                        viewModel.didTapProfile()
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        HealthMeterView(
                            label: "Energy",
                            value: stateManager.athleteState.energy,
                            color: .green
                        )
                        HealthMeterView(
                            label: "Hydration",
                            value: stateManager.athleteState.hydration,
                            color: .blue
                        )
                        HealthMeterView(
                            label: "Focus",
                            value: stateManager.athleteState.mindfulness,
                            color: .purple
                        )
                    }
                    .frame(width: 100)
                }
                .padding(.horizontal)
                .padding(.top, 50)
                
                Spacer()
                
                ActionButtonView(viewModel: viewModel)
                
            }
        }
        // Present Feature Sheets
        .sheet(item: $viewModel.activeSheet) { item in
            switch item {
            case .sleep:
                SleepView()
            case .water:
                WaterView()
            case .exercise:
                ExerciseView()
            case .mindfulness:
                MindfulnessView()
            }
        }
        // Present Game Center *login* sheet if needed
        .sheet(item: $gameCenterManager.identifiableAuthViewController) { controllerWrapper in
            GameCenterAuthView(viewController: controllerWrapper.viewController)
        }
        
        // *** NEW: Present Game Center *profile* sheet when tapped ***
        .sheet(item: $gameCenterManager.identifiableProfileViewController) { controllerWrapper in
            GameCenterAuthView(viewController: controllerWrapper.viewController)
                .ignoresSafeArea() // Let the GC view take over
        }
        
        .environmentObject(stateManager)
    }
}

// *** NEW: Helper View to wrap the UIKit VC ***
struct GameCenterAuthView: UIViewControllerRepresentable {
    let viewController: UIViewController
    
    func makeUIViewController(context: Context) -> UIViewController {
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}

// *** NEW: Helper struct to make UIViewController Identifiable ***
struct IdentifiableUIViewController: Identifiable {
    let id = UUID()
    let viewController: UIViewController
}


// Helper for corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
