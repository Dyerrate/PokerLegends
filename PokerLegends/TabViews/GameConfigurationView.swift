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
    @EnvironmentObject var userModel: UserModel
    
    @State private var settings = GameSettings.default
    @State private var isLaunching = false
    
    let gameTitle: String
    let gameImage: String
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 40) {
                        // Header
                        VStack(alignment: .center, spacing: 8) {
                            Text("Black Jack Settings")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)

                            Text("Customize your game before you start. You can review the basic rules here and visit the Info tab anytime for more help and strategy tips.")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 0)
                        
                        // SharePlay Promo
                        VStack(spacing: 12) {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 40, weight: .semibold))
                                .foregroundColor(.white)
                                .symbolRenderingMode(.hierarchical)

                            Text("Better with friends using SharePlay")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 0)
                        
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
                            
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 0)
                                            }
                    .frame(maxWidth: 600) // cap width so content doesn’t stretch
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    .padding(.horizontal)
                    .containerRelativeFrame(.horizontal, alignment: .center)
                }
                
                // Bottom pinned action area inside the sheet bounds
                HStack {
                    Button(action: { dismiss() }) {
                        Text("Close")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            // Removed the background color as requested
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .shadow(radius: 10)
                    }
                    
                    
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
                        // Removed the background color as requested
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .shadow(radius: 10)
                    }
                    .disabled(isLaunching)
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
                .containerRelativeFrame(.horizontal, alignment: .center)
                .frame(maxWidth: 600)
            }
            .padding(.top) // respect top safe area for content
        }
        .background(
            Image("feltAngleUno")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        )
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

