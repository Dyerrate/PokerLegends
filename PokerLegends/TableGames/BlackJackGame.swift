//
//  BlackJackGame.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 10/6/24.
//

import TabletopKit
import RealityKit
import SwiftUI
import Foundation
import Combine

@Observable
class BlackJackGame: GameProtocol {

    let tabletopGame: TabletopGame
    let renderer: GameRenderer
    let observer: GameObserver
    let setup: GameSetup
    
    func resetGame() {
        print("BlackJackGame: Resetting game...")
        // Call the logic controller's reset/start function
        blackjackLogic.startNewRound()

        // TODO: Add any TabletopKit specific reset logic here
        // e.g., clearing visual elements, resetting entity positions.
    }
    
    @MainActor
    func playerDidHit() {
        // Get the local player's ID (you need a reliable way to do this)
        let localPlayerId = tabletopGame.localPlayer.id.uuid.uuidString // Example
        blackjackLogic.playerAction(playerId: localPlayerId, action: .hit)
    }

    // Example function in BlackJackGame called by a "Stand" button
    @MainActor
    func playerDidStand() {
        let localPlayerId = tabletopGame.localPlayer.id.uuid.uuidString // Example
        blackjackLogic.playerAction(playerId: localPlayerId, action: .stand)
    }
    
    @MainActor // Ensure UI/Tabletop updates happen on the main thread
    private func setupBindings() {
        // Example: Subscribe to gameState changes
        blackjackLogic.$gameState
            .sink { [weak self] newState in
                guard let self = self else { return }
                print("Logic Game State Changed: \(newState)")
                // --- TODO: Update TabletopGame State ---
                // Example: Based on newState, enable/disable UI buttons,
                // show messages, trigger animations via the renderer, etc.
                // This is where you translate abstract logic state to visual/interactive state.
                // self.updateTabletopStateFor(gameState: newState)
            }
            .store(in: &cancellables)

        // Example: Subscribe to player hand changes
        blackjackLogic.$playerHands
             .sink { [weak self] hands in
                 guard let self = self else { return }
                 print("Logic Player Hands Changed: \(hands)")
                 // --- TODO: Update TabletopGame Card Entities ---
                 // For each player ID in hands:
                 // - Find the corresponding player entity/area in TabletopKit.
                 // - Get the cards from hands[playerID].
                 // - Create/update/position card entities in TabletopKit to match the logic hand.
                 //   Use the card's rank, suit, and isFaceUp properties.
                 // self.updateTabletopPlayerHands(hands)
             }
             .store(in: &cancellables)

         // Example: Subscribe to dealer hand changes
         blackjackLogic.$dealerHand
              .sink { [weak self] hand in
                  guard let self = self else { return }
                  print("Logic Dealer Hand Changed: \(hand)")
                  // --- TODO: Update TabletopGame Dealer Card Entities ---
                  // Similar to player hands, update the dealer's card entities.
                  // self.updateTabletopDealerHand(hand)
              }
              .store(in: &cancellables)

         // Add subscriptions for other published properties like playerBets, playerOutcomes etc.
         // ...
    }
    
    private(set) var blackjackLogic: BlackjackLogicController

    private var cancellables = Set<AnyCancellable>()
    
    @MainActor
    init() async {
        // --- Instantiate Logic Controller FIRST ---
        blackjackLogic = BlackjackLogicController(numberOfDecks: 2) // Or your desired number

        // --- Existing Setup ---
        renderer = GameRenderer(typeOfGame: "blackJack")
        setup = GameSetup(root: renderer.root, currentGame: "blackJack")
        tabletopGame = TabletopGame(tableSetup: setup.setup)
        observer = GameObserver(tabletop: tabletopGame, renderer: renderer, gameToRender: "blackJack")
        tabletopGame.addObserver(observer)
        renderer.game = self // Keep the reference if needed by the renderer

        // --- Subscribe to Logic Controller Changes ---
        setupBindings() // Call a new method to handle subscriptions

        // --- Final Setup ---
        tabletopGame.claimAnySeat() // Or handle seat claiming based on game state

        // --- Initial Game State (Example) ---
        // Add the local player (assuming single player for now)
        // You'll need a way to get the local player's unique ID from TabletopKit
        let localPlayerId = tabletopGame.localPlayer.id.uuid.uuidString // Example ID
        blackjackLogic.addPlayer(playerId: localPlayerId)

        // Start the first round automatically (or trigger via UI)
        blackjackLogic.startNewRound()
    }
    
    deinit {
        tabletopGame.removeObserver(observer)
        tabletopGame.removeRenderDelegate(renderer)
    }
    

}
