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
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace // Added for close button

    // Game state managed by BlackJackGame
    @State private var game: BlackJackGame? // Use specific type if possible
    @State private var activityManager: GroupActivityManager?

    // Name matching the entities in your Reality Composer Pro scene
    let startButtonName = "startBJButton"
    let closeButtonName = "closeGameButton" // Added for the close button

    //INFO: This is just the current identifier that will be passed to this view when the users selects a game
    var selectedGame: String

    var body: some View {
        ZStack {
            // Check if the game object exists before showing RealityView
            if let loadedGame = game, activityManager != nil {
                RealityView { (content: inout RealityViewContent) in
                    // The GameRenderer's root (which includes the bjLobby scene) is added here
                    content.add(loadedGame.renderer.root)
                    print("GameTopView: Added game renderer root to RealityView content.")

                    // --- Optional: Verify button entities are present after loading ---
                    // Note: Renderer loads asynchronously, so direct check here might be early.
                    // Verification is better handled within GameRenderer or BlackJackGame after load.
                    // Example (won't work reliably here due to timing):
                    // if loadedGame.renderer.root.findEntity(named: startButtonName) != nil {
                    //     print("Start button found in loaded content (initial check).")
                    // } else {
                    //     print("Start button NOT found in loaded content (initial check).")
                    // }

                } update: { content in
                    // Content updates can happen here if needed
                     print("GameTopView: RealityView update closure called.")
                }
                // --- Add Gesture Recognizer to the RealityView ---
                .gesture(SpatialTapGesture().targetedToAnyEntity().onEnded { value in
                    print("GameTopView: Tap detected on entity: \(value.entity.name)")
                    // Check if the tapped entity is our start button
                    if value.entity.name == startButtonName {
                        handleStartButtonTap()
                    }
                    // Check if the tapped entity is our close button
                    else if value.entity.name == closeButtonName {
                        handleCloseButtonTap()
                    }
                })
                // Add the toolbar only when the game is loaded
                .toolbar() {
                    // Pass the specific BlackJackGame instance
                    GameToolBar(game: loadedGame)
                }
                .tabletopGame(loadedGame.tabletopGame, parent: loadedGame.renderer.root)
            } else {
                // Show a loading indicator while the game is being set up
                ProgressView("Loading Game...")
            }
        }
        .task {
            // Initialize the game asynchronously
            if game == nil { // Only initialize if not already done
                 print("GameTopView: Task started. Initializing BlackJackGame...")
                 // Use await directly as GameTopView is @MainActor
                 let initializedGame = await BlackJackGame()
                 self.game = initializedGame
                 // Ensure activityManager uses the initialized game
                 self.activityManager = GroupActivityManager(tabletopGame: initializedGame.tabletopGame)
                 print("GameTopView: BlackJackGame and ActivityManager initialized.")
            }
        }
        // --- Ensure Reality Composer Pro Entities have necessary components ---
        // Make sure 'startBJButton' and 'closeGameButton' in your Reality Composer Pro
        // project have both InputTargetComponent and CollisionComponent added.
        // Without them, the tap gesture won't register on these entities.
    }

    // --- Action Functions ---
    private func handleStartButtonTap() {
        print("GameTopView: Start Button Tapped!")
        // Call a method on your game logic controller to start the round
        // This assumes BlackJackGame initialization is complete.
        game?.startGameFromLobby()
    }

    private func handleCloseButtonTap() {
        print("GameTopView: Close Button Tapped!")
        // Dismiss the immersive space
        Task {
            await dismissImmersiveSpace()
            // Optional: Add any other cleanup logic if needed
            game?.cleanupBeforeDismiss() // Example cleanup call
        }
    }
}
