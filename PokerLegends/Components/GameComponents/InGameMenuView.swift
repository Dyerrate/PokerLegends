//
//  InGameMenuView.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 1/18/26.
//

import SwiftUI

struct InGameMenuView: View {
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject var session: GameSession
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 25) {
                Text("Game Menu")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(spacing: 20) {
                    // Quick Actions
                    MenuButton(
                        title: "Game Statistics",
                        systemImage: "chart.bar.fill",
                        action: {
                            openWindow(id: "game-stats")
                        }
                    )
                    
                    MenuButton(
                        title: "Player Profile",
                        systemImage: "person.circle.fill",
                        action: {
                            openWindow(id: "player-profile")
                        }
                    )
                    
                    MenuButton(
                        title: "Game Settings",
                        systemImage: "gear.circle.fill",
                        action: {
                            openWindow(id: "game-settings")
                        }
                    )
                    
                    Divider()
                    
                    // Game Controls
                    MenuButton(
                        title: "Pause Game",
                        systemImage: "pause.circle.fill",
                        action: {
                            Task {
                                // Close the menu window first
                                dismissWindow()
                                // Then dismiss the immersive space (pausing the game)
                                await dismissImmersiveSpace()
                                // Update session state to paused
                                session.pause()
                            }
                        }
                    )
                    
                    MenuButton(
                        title: "Save & Exit",
                        systemImage: "square.and.arrow.down.fill",
                        action: {
                            Task {
                                await handleSaveAndExit()
                            }
                        }
                    )
                }
                .padding()
                
                Spacer()
            }
            .padding()
            .frame(minWidth: 300, minHeight: 400)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismissWindow()
                    }
                }
            }
            .background(
                Image("feltAngleUno")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            )
        }
        
    }
    
    // MARK: - Private Methods
    
    private func handleSaveAndExit() async {
        print("InGameMenuView: Saving game and exiting...")
        
        // Save game state
        await saveGameState()
        
        // Close the menu window first
        dismissWindow()
        
        // Then dismiss the immersive space
        await dismissImmersiveSpace()
        
        // Update session phase to finished
        session.endGame()
        
        print("InGameMenuView: Successfully saved and exited game")
    }
    
    private func saveGameState() async {
        // Implement your save logic here
        // This could involve:
        // - Saving current game progress to UserDefaults, Core Data, or CloudKit
        // - Saving player statistics
        // - Saving current bet amounts and game state
        
        // Example implementation:
        do {
            let gameData: [String: Any] = [
                "timestamp": Date(),
                "gameInProgress": true,
                // Add other relevant game state data here
            ]
            
            // Save to UserDefaults (or use your preferred persistence method)
            UserDefaults.standard.set(gameData, forKey: "savedGameState")
            
            // Simulate save delay
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            print("Game state saved successfully")
        } catch {
            print("Failed to save game state: \(error)")
        }
    }
}

struct MenuButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 30)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    InGameMenuView()
}
