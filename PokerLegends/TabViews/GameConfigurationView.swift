//
//  GameConfigurationView.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 10/25/25.
//

//

import SwiftUI

struct GameConfigurationView: View {
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var session: GameSession
    
    @State private var settings = GameSettings.default
    @State private var isLaunching = false
    
    let gameTitle: String
    let gameImage: String
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background removed as requested
//                LinearGradient(
//                    colors: [.black, .gray.opacity(0.8)],
//                    startPoint: .topLeading,
//                    endPoint: .bottomTrailing
//                )
//                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 40) {
                            // Header removed for simplified view
//                            VStack(spacing: 10) {
//                                Image(gameImage)
//                                    .resizable()
//                                    .aspectRatio(contentMode: .fit)
//                                    .frame(height: 150)
//                                    .clipShape(RoundedRectangle(cornerRadius: 20))
//                                    .shadow(radius: 10)
//                                
//                                Text("Configure Your Game")
//                                    .font(.extraLargeTitle)
//                                    .fontWeight(.bold)
//                                
//                                Text(gameTitle)
//                                    .font(.title2)
//                                    .foregroundColor(.secondary)
//                            }
//                            .padding(.top, 30)
                            
                            // Theme selection removed for simplified view
//                            VStack(alignment: .leading, spacing: 15) {
//                                Label("Table Theme", systemImage: "paintbrush.fill")
//                                    .font(.title2)
//                                    .fontWeight(.bold)
//                                
//                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
//                                    ForEach(GameSettings.GameTheme.allCases, id: \.self) { theme in
//                                        ThemeCard(
//                                            theme: theme,
//                                            isSelected: settings.theme == theme
//                                        ) {
//                                            settings.theme = theme
//                                        }
//                                    }
//                                }
//                            }
//                            .padding(.horizontal)
                            
                            // Location selection removed for simplified view
//                            VStack(alignment: .leading, spacing: 15) {
//                                Label("Casino Location", systemImage: "location.fill")
//                                    .font(.title2)
//                                    .fontWeight(.bold)
//                                
//                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
//                                    ForEach(GameSettings.GameLocation.allCases, id: \.self) { location in
//                                        LocationCard(
//                                            location: location,
//                                            isSelected: settings.location == location
//                                        ) {
//                                            settings.location = location
//                                        }
//                                    }
//                                }
//                            }
//                            .padding(.horizontal)
                            
                            // Number of Decks
                            VStack(alignment: .leading, spacing: 15) {
                                Label("Number of Decks", systemImage: "square.stack.3d.up.fill")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                VStack {
                                    Text("Decks: \(settings.numberOfDecks)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Slider(
                                        value: Binding(
                                            get: { Double(settings.numberOfDecks) },
                                            set: { settings.numberOfDecks = Int($0.rounded()) }
                                        ),
                                        in: 1...8,
                                        step: 1
                                    )
                                }
                                
                                Text("More decks = harder to count cards")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 5)
                            }
                            .padding(.horizontal)
                            
                            Spacer(minLength: 40)
                            
//                            // Start button retained; green background removed
//                            Button(action: launchGame) {
//                                HStack {
//                                    if isLaunching {
//                                        ProgressView()
//                                            .tint(.white)
//                                    } else {
//                                        Image(systemName: "play.fill")
//                                        Text("Start Game")
//                                            .fontWeight(.bold)
//                                    }
//                                }
//                                .font(.title2)
//                                .foregroundColor(.white)
//                                .frame(maxWidth: 400)
//                                .padding(.vertical, 20)
//                                .shadow(radius: 10)
//                            }
//                            .disabled(isLaunching)
//                            .padding(.horizontal)
//                            .padding(.bottom, 30)
                        }
                    }
                    // Bottom pinned action area
                    VStack {
                        Button(action: launchGame) {
                            HStack {
                                if isLaunching {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "play.fill")
                                    Text("Start Game")
                                        .fontWeight(.bold)
                                }
                            }
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .shadow(radius: 10)
                        }
                        .disabled(isLaunching)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private func launchGame() {
        isLaunching = true
        
        // Save settings for the game to use        
        Task {
            // Small delay for visual feedback
            try? await Task.sleep(for: .seconds(0.5))
            session.beginGame(with: settings)
            let result = await openImmersiveSpace(id: "GameView")
            
            if case .error = result {
                print("Error opening immersive space")
                isLaunching = false
            } else {
                // Dismiss this config view after successfully opening game
                dismiss()
            }
        }
    }
}

// MARK: - Theme Card Component
struct ThemeCard: View {
    let theme: GameSettings.GameTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: theme.icon)
                    .font(.system(size: 40))
                    .foregroundColor(isSelected ? .green : .white)
                
                Text(theme.rawValue)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(theme.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isSelected ? Color.green.opacity(0.2) : Color.gray.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(isSelected ? Color.green : Color.clear, lineWidth: 3)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Location Card Component
struct LocationCard: View {
    let location: GameSettings.GameLocation
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: location.icon)
                    .font(.system(size: 40))
                    .foregroundColor(isSelected ? .yellow : .white)
                
                Text(location.rawValue)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(location.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isSelected ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 3)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Deck Count Button Component
struct DeckCountButton: View {
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Text("\(count)")
                    .font(.title)
                    .fontWeight(.bold)
                Text("deck\(count > 1 ? "s" : "")")
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .white : .secondary)
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview("Game Config - Preview") {
    // Provide a lightweight mock session if needed
    let session = GameSession()
    // Optionally set any default settings for preview
    // session.settings = .default

    return GameConfigurationView(
        gameTitle: "Blackjack",
        gameImage: "blackjackHeader" // Use an asset that exists in your project
    )
    .environmentObject(session)
}
