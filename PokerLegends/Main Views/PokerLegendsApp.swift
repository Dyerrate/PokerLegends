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

    var body: some Scene {
        WindowGroup(id: "MainView") {
            MainView()
                .environmentObject(userManager)
                .frame (minWidth: 1200, maxWidth: 1280, minHeight: 650, maxHeight: 900)

        }
        //Need to make a panel to appear before the user starts the game that will control the game but will be the same regardless of the gametype except there should be diferent starting options for games
        
        WindowGroup(id: "GameControlPanel") {
            
        }
        .windowResizability(.contentSize)
        
        ImmersiveSpace(id: "GameView") {
            GameTopView(selectedGame: "blackJack")
        }
    
    }
}
