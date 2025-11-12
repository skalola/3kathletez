//
//  SoundPickerView.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/9/25.
//

import Foundation
import SwiftUI

struct SoundPickerView: View {
    
    // This is how the view gets and sets the selected sound
    @Binding var selectedSound: String
    @Environment(\.dismiss) var dismiss
    
    // This is our list of bundled sounds.
    // "Default" uses the system's critical alert.
    // "loud_alarm.caf" must be a real file in your project bundle.
    let sounds = [
        "Default",
        "loud_alarm.caf"
        // TODO: Add other sound file names here (e.g., "Radar.caf")
    ]
    
    var body: some View {
        NavigationView {
            List(sounds, id: \.self) { sound in
                Button(action: {
                    selectedSound = sound
                    dismiss()
                }) {
                    HStack {
                        Text(sound.replacingOccurrences(of: ".caf", with: ""))
                            .foregroundColor(.white)
                        Spacer()
                        if selectedSound == sound {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Select Sound")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .scrollContentBackground(.hidden)
            .background(StarryNightView().ignoresSafeArea()) // Reuse background
        }
    }
}
