//
//  SleepView.swift
//  Locker Room
//
//  Created by Shiv Kalola on 11/9/25.
//

import SwiftUI

// Helper struct for the bed time rows
struct BedTimeRow: Identifiable {
    let id: String
    let label: String
    let time: String
}

struct SleepView: View {
    
    // --- THIS IS THE FIX for "Missing argument" ---
    @StateObject private var viewModel: SleepViewModel
    
    @Environment(\.dismiss) private var dismiss
    
    // The view *requires* this callback to be passed in.
    var onAlarmSet: (AppAlarm) -> Void
    
    // --- NEW INIT ---
    // This is how the parent (ContentView) passes the callback
    // to the StateObject (viewModel).
    init(onAlarmSet: @escaping (AppAlarm) -> Void) {
        self.onAlarmSet = onAlarmSet
        _viewModel = StateObject(wrappedValue: SleepViewModel(onAlarmSet: onAlarmSet))
    }
    // --- END FIX ---
    
    private var bedTimeRows: [BedTimeRow] {
        zip(viewModel.bedTimeLabels, viewModel.bedTimeStrings).map {
            BedTimeRow(id: $0.0, label: $0.0, time: $0.1)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                StarryNightView()
                    .ignoresSafeArea()
                
                if viewModel.isCalculating {
                    // --- FIX: CalculatingView is now defined below ---
                    CalculatingView()
                }
                
                List {
                    // --- SECTION 1: ACTIVE ALARMS (MOVED TO TOP) ---
                    if !viewModel.alarms.isEmpty {
                        alarmsSection
                    }
                    
                    // --- SECTION 2: INPUTS ---
                    inputSection
                    
                    // --- SECTION 3: RESULTS (with new transition) ---
                    if let schedule = viewModel.schedule {
                        resultsSection(schedule: schedule)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .disabled(viewModel.isCalculating)
            }
            .navigationTitle("Sleep Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                viewModel.checkNotificationAccess()
                // We no longer set the callback here, it's done in the init
            }
            .sheet(isPresented: $viewModel.isShowingMapView) {
                // When sheet is dismissed, update travel time message
                if viewModel.travelTime > 0 {
                    let formatter = DateComponentsFormatter()
                    formatter.unitsStyle = .abbreviated
                    formatter.allowedUnits = [.hour, .minute]
                    viewModel.travelTimeMessage = formatter.string(from: viewModel.travelTime) ?? "Error"
                    
                    viewModel.isAddingCommute = true // Enable the commute
                    viewModel.calculateSchedule() // Recalculate
                }
            } content: {
                MapView(
                    estimatedTravelTime: $viewModel.travelTime,
                    destinationName: $viewModel.travelDestinationName
                )
            }
            .sheet(isPresented: $viewModel.isShowingSoundPicker) {
                SoundPickerView(selectedSound: $viewModel.soundName)
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var inputSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 15) {
                Text("What time do you want to ARRIVE?")
                    .font(.title3.weight(.semibold))
                    .padding(.top)
                    .foregroundColor(.white)
                    .shadow(color: .white, radius: 2)

                DatePicker(
                    "Desired Arrival Time",
                    selection: $viewModel.arrivalTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .colorInvert()
                .colorMultiply(.white)
                .shadow(color: .white.opacity(0.7), radius: 3, x: 0, y: 0)
                
                Picker("Repeat", selection: $viewModel.repeatFrequency) {
                    ForEach(AlarmRepeatFrequency.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(.segmented)
                
                Button(action: {
                    viewModel.isShowingSoundPicker = true
                }) {
                    HStack {
                        Text("Wake up sound")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Text(viewModel.soundName.replacingOccurrences(of: ".caf", with: ""))
                            .foregroundColor(.gray)
                        Image(systemName: "chevron.right")
                    }
                }
                .tint(.green)
                .controlSize(.large)
                .buttonStyle(.bordered)
                
                Button(action: {}) {
                    HStack {
                        Text("Morning Routine")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Button {
                            viewModel.routineTime = max(0, viewModel.routineTime - 5)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                        }
                        Text("\(Int(viewModel.routineTime)) min")
                            .font(.body.monospacedDigit())
                            .frame(width: 60)
                            .foregroundColor(.white)
                        Button {
                            viewModel.routineTime += 5
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                    .buttonStyle(.plain)
                }
                .tint(.orange)
                .controlSize(.large)
                .buttonStyle(.bordered)
                
                
                Button(action: {
                    viewModel.commuteButtonTapped()
                }) {
                    HStack {
                        if viewModel.travelTime == 0 {
                            Text("Add Commute Time")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Est. commute to \(viewModel.travelDestinationName)")
                                .font(.caption)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            
                            Spacer()
                            
                            Text(viewModel.travelTimeMessage)
                                .font(.headline)
                        }
                    }
                    .foregroundColor(viewModel.travelTime == 0 ? .white : (viewModel.isAddingCommute ? .white : .gray))
                }
                .tint(viewModel.travelTime == 0 ? .red : (viewModel.isAddingCommute ? .red : .gray))
                .controlSize(.large)
                .buttonStyle(.bordered)
            }
            
            Button("Calculate Sleep Schedule", action: viewModel.calculateSchedule)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .tint(.blue)
                .controlSize(.large)
        }
        .listRowBackground(Color.black.opacity(0.3))
        .buttonStyle(.bordered)
    }
    
    private func resultsSection(schedule: SleepSchedule) -> some View {
        Section {
            VStack(alignment: .center, spacing: 10) {
                Text("RECOMMENDED WAKE-UP")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
                
                HStack(spacing: 10) {
                    Text("☀️")
                        .font(.system(size: 30))
                    Text(schedule.recommendedWakeUp, style: .time)
                        .font(.system(size: 40, weight: .bold))
                }
                .foregroundColor(.white)
                .shadow(color: .white.opacity(0.8), radius: 5)
                
                Text(schedule.recommendedWakeUp, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 10)
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Based on sleep cycles, you should go to bed at one of these times to wake up refreshed:")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                ForEach(bedTimeRows) { bedTime in
                    HStack {
                        Text("🌙 \(bedTime.label)")
                            .font(.caption.weight(.bold))
                            .textCase(.uppercase)
                        
                        Spacer()
                        
                        Text(bedTime.time)
                            .font(.title3.weight(.bold))
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding(.vertical, 5)

            if viewModel.hasNotificationAccess {
                Button("Set Alarm", action: {
                    viewModel.setAlarm() // This calls the callback
                    dismiss() // Dismiss the sheet
                })
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .tint(.meterIndigo)
            } else {
                Button("Request Notification Permission", action: viewModel.requestNotificationAccess)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .tint(.orange)
            }
        }
        .listRowBackground(Color.black.opacity(0.3))
        .buttonStyle(.borderedProminent)
    }
    
    private var alarmsSection: some View {
        Section("Active Alarms") {
            // We use ForEach($viewModel.alarms) to get a *binding*
            // This is what lets the Toggle directly change the alarm's state
            ForEach(viewModel.alarms) { alarm in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(alarm.wakeUpTime, style: .time)
                            .font(.largeTitle)
                            .foregroundColor(alarm.isEnabled ? .white : .gray)
                        
                        Text("\(alarm.repeatFrequency.rawValue) • \(alarm.soundName.replacingOccurrences(of: ".caf", with: ""))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { alarm.isEnabled },
                        set: { _ in
                            guard let index = viewModel.alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
                            viewModel.alarms[index].isEnabled.toggle()
                            viewModel.toggleAlarm(viewModel.alarms[index])
                        }
                    ))
                    .labelsHidden()
                    .tint(.blue)
                }
            }
            .onDelete { indexSet in
                viewModel.deleteAlarm(at: indexSet)
            }
        }
        .listRowBackground(Color.black.opacity(0.3))
    }
}

// --- FIX: RE-ADDED CalculatingView ---
private struct CalculatingView: View {
    @State private var zOffset: [Double] = [-60, -80, -100]
    @State private var opacity: Double = 1.0

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .transition(.opacity)

            VStack {
                ForEach(0..<3) { i in
                    Text("Z")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(opacity)
                        .offset(y: zOffset[i])
                        .animation(
                            .easeInOut(duration: 1.0)
                                .repeatForever()
                                .delay(Double(i) * 0.3),
                            value: zOffset[i]
                        )
                }
            }
            .onAppear {
                withAnimation {
                    opacity = 0
                    zOffset[0] = 40
                    zOffset[1] = 20
                    zOffset[2] = 0
                }
            }
            
            Text("Calculating...")
                .font(.title2)
                .foregroundColor(.white)
                .padding(.top, 150)
        }
        .zIndex(10)
    }
}
// --- END OF FIX ---

#Preview {
    SleepView(onAlarmSet: { _ in })
}
