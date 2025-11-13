//
//  WaterView.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/9/25.
//
import SwiftUI

struct WaterView: View {
    @EnvironmentObject var stateManager: AvatarStateManager
    @StateObject private var viewModel: WaterViewModel

    init() {
        // Create a temporary VM. It will be replaced .onAppear
        // *** FIX: Pass a mock service to the temp stateManager ***
        let tempService = PersistenceService(isMock: true)
        let tempManager = AvatarStateManager(persistenceService: tempService)
        _viewModel = StateObject(wrappedValue: WaterViewModel(stateManager: tempManager))
    }

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Log Water")) {
                    // *** FIX: This now correctly binds to a String ***
                    TextField("Ounces (oz)", text: $viewModel.waterIntake)
                        .keyboardType(.decimalPad)
                }
                
                Button("Log Water") {
                    viewModel.logWater()
                    dismiss()
                }
            }
            .navigationTitle("Hydration")
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

struct WaterView_Previews: PreviewProvider {
    static var previews: some View {
        WaterView()
            // *** FIX: This init now works ***
            .environmentObject(AvatarStateManager(persistenceService: PersistenceService(isMock: true)))
    }
}
