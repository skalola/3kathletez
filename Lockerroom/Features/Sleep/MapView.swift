//
//  MapView.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/9/25.
//

import SwiftUI
import MapKit

struct MapView: View {
    
    @StateObject private var viewModel = MapViewModel()
    @Binding var estimatedTravelTime: TimeInterval // Bind back to SleepViewModel
    @Binding var destinationName: String // <-- NEW BINDING
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                
                // --- Search Bar ---
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search for a destination...", text: $viewModel.searchText)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding()
                
                Picker("Transport Type", selection: $viewModel.transportType) {
                    ForEach(TransportType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: viewModel.transportType) {
                    if let location = viewModel.selectedLocation {
                        viewModel.calculateTravelTime(to: location)
                    }
                }
                
                // --- Search Results List ---
                List(viewModel.searchResults, id: \.self) { item in
                    Button(action: {
                        viewModel.calculateTravelTime(to: item)
                    }) {
                        VStack(alignment: .leading) {
                            Text(item.name ?? "Unknown")
                                .font(.headline)
                            Text(item.placemark.title ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .listStyle(.plain)
                
                // --- Selected Destination & Time ---
                if let location = viewModel.selectedLocation {
                    VStack {
                        Text(location.name ?? "")
                            .font(.headline)
                        Text("Est. Commute: \(viewModel.travelTimeMessage)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button("Set Travel Time") {
                            if let time = viewModel.travelTime {
                                self.estimatedTravelTime = time
                                self.destinationName = viewModel.destinationName // <-- PASS NAME BACK
                                dismiss()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(viewModel.travelTime == nil)
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Destination")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                viewModel.checkLocationServices()
            }
        }
    }
}
