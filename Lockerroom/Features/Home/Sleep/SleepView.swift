//
//  SleepView.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/9/25.
//

import SwiftUI
import MapKit

struct SleepView: View {
    // 1. Get the "brain" from the environment
    @EnvironmentObject var stateManager: AvatarStateManager
    
    // 2. Create a ViewModel just for this View's logic
    @StateObject private var viewModel: SleepViewModel
    
    // 3. Dismiss action
    @Environment(\.dismiss) private var dismiss
    
    // 4. Init to create the ViewModel
    init() {
        // This is a common pattern to inject an EnvironmentObject
        // into a StateObject. It's a bit of a placeholder.
        let tempService = PersistenceService(isMock: true)
        _viewModel = StateObject(wrappedValue: SleepViewModel(
            stateManager: AvatarStateManager(persistenceService: tempService)
        ))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("Mode", selection: $viewModel.selectedTab) {
                    Text("Plan Sleep").tag(SleepViewTab.plan)
                    Text("Log Sleep").tag(SleepViewTab.log)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                if viewModel.selectedTab == .plan {
                    Form {
                        Section(header: Text("1. Set Your Day")) {
                            DatePicker("Start My Day Time", selection: $viewModel.finalWakeUpTime, displayedComponents: .hourAndMinute)
                            Stepper("Morning Routine: \(Int(viewModel.routineTime)) min", value: $viewModel.routineTime, in: 0...120, step: 5)
                        }
                        
                        // ---
                        // *** NEW: Added the MapView here ***
                        // This connects your MapViewModel to the SleepView UI
                        // ---
                        Section(header: Text("2. Commute (Optional)"),
                                footer: Text("Select a destination to automatically add commute time to your calculation.")) {
                            
                            // This embeds the MapView we just fixed
                            MapView(viewModel: viewModel.mapViewModel)
                                .frame(height: 300)
                        }
                        
                        Section(header: Text("3. Recommended Bedtimes")) {
                            if viewModel.recommendedBedtimes.isEmpty {
                                Text("Calculating...")
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(viewModel.recommendedBedtimes, id: \.self) { time in
                                    Text(time, style: .time)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                        
                        Button(action: {
                            viewModel.scheduleAlarm()
                            dismiss() // Close the sheet
                        }) {
                            Text("Set Bedtime Alarm")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .listRowInsets(EdgeInsets()) // Make button full width
                    }
                }

                if viewModel.selectedTab == .log {
                    Form {
                        Section(header: Text("Log Manually")) {
                            DatePicker("Slept From", selection: $viewModel.sleepStartTime, displayedComponents: [.date, .hourAndMinute])
                            DatePicker("Slept Until", selection: $viewModel.sleepEndTime, displayedComponents: [.date, .hourAndMinute])
                        }
                        
                        Button(action: {
                            viewModel.logSleep()
                            dismiss() // Close the sheet
                        }) {
                            Text("Log Sleep Session")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .listRowInsets(EdgeInsets())
                    }
                }
            }
            .navigationTitle("Sleep")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
        .onAppear {
            // 5. Once the view appears, the environment is ready.
            //
            // *** THIS IS THE FIX ***
            // We now update the 'stateManager' property on the
            // existing 'viewModel' instead of trying to create a new one.
            //
            if viewModel.stateManager.persistenceService.isMock {
                viewModel.stateManager = stateManager
            }
        }
    }
}

// MARK: - Preview
struct SleepView_Previews: PreviewProvider {
    static var previews: some View {
        SleepView()
            .environmentObject(AvatarStateManager(persistenceService: PersistenceService(isMock: true)))
    }
}
