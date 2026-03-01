//
//  PlayerProfileView.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 1/18/26.
//

import SwiftUI

struct PlayerProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var playerName = "Player 1"
    @State private var avatarSelection = 0
    
    private let avatars = ["🎩", "🎭", "🎪", "🎯", "🎲", "🃏"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 25) {
                Text("Player Profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Avatar Selection
                VStack(spacing: 15) {
                    Text("Choose Your Avatar")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 15) {
                        ForEach(0..<avatars.count, id: \.self) { index in
                            Button(action: {
                                avatarSelection = index
                            }) {
                                Text(avatars[index])
                                    .font(.system(size: 40))
                                    .frame(width: 60, height: 60)
                                    .background(avatarSelection == index ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
                                    .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
                
                // Player Name
                VStack(alignment: .leading, spacing: 10) {
                    Text("Player Name")
                        .font(.headline)
                    
                    TextField("Enter your name", text: $playerName)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        // Save profile changes
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PlayerProfileView()
}