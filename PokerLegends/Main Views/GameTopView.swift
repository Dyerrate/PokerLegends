//
//  GameTopView.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 10/5/24.
//


import Foundation
import SwiftUI
import TabletopKit
import RealityKit


@MainActor
struct GameTopView: View {
    @Environment(\.realityKitScene) private var scene
    @State private var game: GameProtocol?
    @State private var activityManager: GroupActivityManager?

    //INFO: This is just the current identifier that will be passed to this view when the users selects a game
    var selectedGame: String
    
    var body: some View {
        ZStack {
            if let loadedGame = game, activityManager != nil {
                RealityView { (content: inout RealityViewContent) in
                    //Review what we are adding here as this was from test data- portal world etc
                    content.entities.append(loadedGame.renderer.root)
                    content.add(loadedGame.renderer.portalWorld)
                    content.add(loadedGame.renderer.portal)
                }.toolbar() {
                    GameToolBar(game: loadedGame)
                }.tabletopGame(loadedGame.tabletopGame, parent: loadedGame.renderer.root)
            }
        }
        
        //TODO: Need to fix this part as it is hardcoded or testing
        .task {
            if(selectedGame == "blackJack") {
                self.game = await BlackJackGame()
                self.activityManager = .init(tabletopGame: game!.tabletopGame)
            }
            
        }
    }
}

