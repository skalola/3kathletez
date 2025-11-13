//
//  MapView.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/13/25.
//

import SwiftUI
import MapKit

/// This is the corrected MapView.
/// 1. It uses `@ObservedObject` to fix the "Wrapper" error.
/// 2. It binds to `selectedDestination` to fix the "Dynamic Member" error.
struct MapView: View {
    
    // *** FIX 1: This must be @ObservedObject ***
    @ObservedObject var viewModel: MapViewModel
    
    var body: some View {
        VStack {
            // 1. Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search for a destination...", text: $viewModel.searchText)
                    .autocorrectionDisabled()
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)

            // 2. Transport Type
            Picker("Transport", selection: $viewModel.transportType) {
                ForEach(TransportType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            // 3. Search Results List
            List(viewModel.searchResults, id: \.self, selection: $viewModel.selectedDestination) { item in
                // *** FIX 2: Binds to `selectedDestination` ***
                VStack(alignment: .leading) {
                    Text(item.name ?? "Unknown")
                        .font(.headline)
                    Text(item.placemark.title ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .listStyle(PlainListStyle())
            
            // 4. Commute Time
            if !viewModel.travelTimeMessage.isEmpty {
                Text(viewModel.travelTimeMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 5)
            }
        }
        .onAppear {
            viewModel.checkLocationServices()
        }
    }
}
