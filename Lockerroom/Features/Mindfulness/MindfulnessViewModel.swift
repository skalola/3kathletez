//
//  MindfulnessViewModel.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/9/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class MindfulnessViewModel: ObservableObject {
    
    @Published var minutes: Double = 5
    
    // Logic for tracking sessions will go here
    
    func logMindfulness(homeViewModel: HomeViewModel) {
        let minutes = Int(self.minutes)
        if minutes > 0 {
            homeViewModel.logMindfulness(minutes: minutes)
        }
    }
}
