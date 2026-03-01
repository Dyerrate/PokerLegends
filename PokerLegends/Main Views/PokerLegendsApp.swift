//
//  PokerLegendsApp.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 6/30/24.
//

import SwiftUI

@MainActor
@main
struct PokerLegendsApp: App {
    var userManager = UserManager()
    @StateObject private var session = GameSession()
    var body: some Scene {
        WindowGroup(id: "MainView") {
            MainView()
                .environmentObject(userManager)
                .environmentObject(session)
                .frame (minWidth: 1200, maxWidth: 1280, minHeight: 650, maxHeight: 900)

        }
        //Need to make a panel to appear before the user starts the game that will control the game but will be the same regardless of the gametype except there should be diferent starting options for games
        
        WindowGroup(id: "GameControlPanel") {
            
        }
        .windowResizability(.contentSize)
        
        // In-Game Menu Window
        WindowGroup(id: "game-menu") {
            InGameMenuView()
                .environmentObject(session)
                .environmentObject(userManager)
        }
        .windowResizability(.contentSize)
        .windowStyle(.plain)
        
        // Game Statistics Window
        WindowGroup(id: "game-stats") {
            GameStatsView()
                .environmentObject(session)
        }
        .windowResizability(.contentSize)
        .windowStyle(.plain)
        
        // Player Profile Window
        WindowGroup(id: "player-profile") {
            PlayerProfileView()
                .environmentObject(session)
                .environmentObject(userManager)
        }
        .windowResizability(.contentSize)
        .windowStyle(.plain)
        
        // Game Settings Window
        WindowGroup(id: "game-settings") {
            GameSettingsView()
                .environmentObject(session)
        }
        .windowResizability(.contentSize)
        .windowStyle(.plain)
        
        
        
        //GAME SPACE
        ImmersiveSpace(id: "GameView") {
            Group {
                if case .authenticated(let userModel) = userManager.session {
                    GameTopView(selectedGame: "blackJack")
                        .environmentObject(session)
                        .environmentObject(userModel)
                } else {
                    // Optionally, show a placeholder, loading, or error view
                    Text("Please sign in to play.")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                }
            }
        }
    
    }
}
