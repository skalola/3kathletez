//
//  MindfulnessView.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/9/25.
//
import SwiftUI

struct MindfulnessView: View {
    @EnvironmentObject var stateManager: AvatarStateManager
    @StateObject private var viewModel: MindfulnessViewModel

    init() {
        // *** FIX: Pass a mock service to the temp stateManager ***
        let tempService = PersistenceService(isMock: true)
        let tempManager = AvatarStateManager(persistenceService: tempService)
        _viewModel = StateObject(wrappedValue: MindfulnessViewModel(stateManager: tempManager))
    }
    
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Log Session")) {
                    // *** FIX: This now correctly binds to a String ***
                    TextField("Minutes", text: $viewModel.mindfulnessMinutes)
                        .keyboardType(.decimalPad)
                    DatePicker("Date", selection: $viewModel.date, displayedComponents: .date)
                }
                
                Button("Log Session") {
                    viewModel.logSession()
                    dismiss()
                }
            }
            .navigationTitle("Mindfulness")
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

struct MindfulnessView_Previews: PreviewProvider {
    static var previews: some View {
        MindfulnessView()
            // *** FIX: This init now works ***
            .environmentObject(AvatarStateManager(persistenceService: PersistenceService(isMock: true)))
    }
}
