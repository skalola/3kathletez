//
//  ExerciseView.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/9/25.
//
import SwiftUI

struct ExerciseView: View {
    @EnvironmentObject var stateManager: AvatarStateManager
    @StateObject private var viewModel: ExerciseViewModel
    
    init() {
        // *** FIX: Pass a mock service to the temp stateManager ***
        let tempService = PersistenceService(isMock: true)
        let tempManager = AvatarStateManager(persistenceService: tempService)
        _viewModel = StateObject(wrappedValue: ExerciseViewModel(stateManager: tempManager))
    }
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Log Workout")) {
                    TextField("Workout Name (e.g., Run, Lift)", text: $viewModel.activityName)
                    TextField("Calories Burned", text: $viewModel.caloriesBurned)
                        .keyboardType(.numberPad)
                    DatePicker("Date", selection: $viewModel.date, displayedComponents: .date)
                    Slider(value: $viewModel.duration, in: 0...120, step: 5) {
                        Text("Duration: \(viewModel.duration, specifier: "%.0f") min")
                    }
                }
                
                Button("Log Workout") {
                    viewModel.logWorkout()
                    dismiss()
                }
            }
            .navigationTitle("Exercise")
            .navigationBarItems(leading: Button("Cancel") { dismiss() })
        }
        .onAppear {
            // *** FIX: This logic will now work ***
            if viewModel.stateManager.persistenceService.isMock {
                // Replace the mock VM with one using the *real* stateManager from the environment
                viewModel.stateManager = stateManager
            }
        }
    }
}

struct ExerciseView_Previews: PreviewProvider {
    static var previews: some View {
        ExerciseView()
            // *** FIX: This init now works ***
            .environmentObject(AvatarStateManager(persistenceService: PersistenceService(isMock: true)))
    }
}
