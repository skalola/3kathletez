//
//  ExerciseView.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/10/25.
//

import SwiftUI

// --- We no longer need the SchedulableActivity struct ---

struct ExerciseView: View {
    
    @EnvironmentObject var homeViewModel: HomeViewModel
    @StateObject var viewModel = ExerciseViewModel()
    @Environment(\.dismiss) var dismiss
    
    // --- The 'onSchedule' callback is GONE ---
    
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gray.opacity(0.8).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Select an Activity to Log")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .padding(.top, 20)
                        
                        LazyVGrid(columns: columns, spacing: 15) {
                            ForEach(viewModel.activityTypes, id: \.0) { (name, icon) in
                                // --- UPDATED: This button now sets the selection ---
                                ActivityButton(
                                    name: name,
                                    icon: icon,
                                    isSelected: viewModel.selectedActivity == name
                                ) {
                                    viewModel.selectActivity(name)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // --- This is the original logging UI ---
                        if viewModel.selectedActivity != nil {
                            LogActivitySheet
                        }
                        
                        // --- This is the original log table ---
                        ActivityLogTable(
                            loggedActivities: viewModel.loggedActivities,
                            onDelete: { offsets in
                                viewModel.loggedActivities.remove(atOffsets: offsets)
                                // We should also update persistence here
                            }
                        )
                    }
                }
                .navigationTitle("Log Workout")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                    }
                }
                // --- The .sheet(item:) modifier is GONE ---
            }
        }
    }
    
    // --- This is the original Logging UI ---
    private var LogActivitySheet: some View {
        VStack(spacing: 15) {
            Text("Logging \(viewModel.selectedActivity ?? "")")
                .font(.headline)
                .foregroundColor(.white)
            
            Stepper(value: $viewModel.logMinutes, in: 5...180, step: 5) {
                Text("\(Int(viewModel.logMinutes)) Minutes")
                    .font(.title2.bold().monospacedDigit())
                    .foregroundColor(.green)
            }
            
            Button("LOG ACTIVITY", action: {
                viewModel.logActivity(homeViewModel: homeViewModel)
            })
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
        .background(Color.black.opacity(0.5))
        .cornerRadius(15)
        .padding(.horizontal)
        .transition(.slide)
    }
}

// --- This is the original, simple log table ---
private struct ActivityLogTable: View {
    
    var loggedActivities: [LoggedActivity]
    var onDelete: (IndexSet) -> Void // Add delete action
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Activity History")
                .font(.title3.bold())
                .foregroundColor(.white)
                .padding(.horizontal)
            
            if loggedActivities.isEmpty {
                Text("No workouts logged yet.")
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            } else {
                List {
                    ForEach(loggedActivities.reversed()) { activity in
                        HStack {
                            Image(systemName: activity.icon)
                                .foregroundColor(.green)
                            
                            VStack(alignment: .leading) {
                                Text(activity.name)
                                    .font(.headline)
                                Text(activity.date, style: .date)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Text("\(activity.minutes) min") // Use .minutes
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        .listRowBackground(Color.black.opacity(0.3))
                    }
                    .onDelete(perform: onDelete) // Add swipe to delete
                }
                .frame(height: min(CGFloat(loggedActivities.count) * 60, 300))
                .cornerRadius(15)
                .listStyle(.plain)
            }
        }
        .padding(.vertical)
    }
}

private struct ActivityButton: View {
    let name: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.largeTitle)
                Text(name)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(isSelected ? Color.green.opacity(0.8) : Color.black.opacity(0.5))
            .foregroundColor(isSelected ? .black : .white)
            .cornerRadius(15)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(), value: isSelected)
        }
    }
}
