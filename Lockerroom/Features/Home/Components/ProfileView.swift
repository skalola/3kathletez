//
//  ProfileView.swift
//  Lockerroom
//
//  Created by Shiv Kalola on 11/9/25.
//
import SwiftUI

/// This is the corrected ProfileView.
/// It is now a "dumb" view that just displays the data passed into it.
struct ProfileView: View {
    
    // MARK: - Properties
    
    // These are passed in from ContentView
    let name: String
    let level: Int
    
    // *** NEW: This will display the Game Center photo ***
    let image: UIImage?
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            // MARK: - Avatar Image
            
            // *** NEW: Logic to display photo or fallback ***
            Group {
                if let uiImage = image {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    // Fallback system icon
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .shadow(radius: 5)
            
            // MARK: - Name and Level
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("Level \(level)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.3))
        .cornerRadius(30)
    }
}

// MARK: - Preview Provider

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ProfileView(name: "Test Athlete", level: 42, image: nil)
            
            ProfileView(name: "Athlete With Pic", level: 10, image: UIImage(systemName: "person.fill"))
        }
        .padding()
        .background(Color.gray)
        .previewLayout(.sizeThatFits)
    }
}
