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
import Combine


@MainActor
struct GameTopView: View {
    @Environment(\.realityKitScene) private var scene
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace // Added for close button

    // Game state managed by BlackJackGame
    @State private var game: BlackJackGame? // Use specific type if possible
    @State private var activityManager: GroupActivityManager?
    @State private var hoverSub: Cancellable?
    @State private var initialOffsetFromChipToTouch: SIMD3<Float>? = nil

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
                    content.subscribe(to: CollisionEvents.Began.self) { event in
                         let a = event.entityA
                         let b = event.entityB

                     //    print("🧩 Collision began:")
                     //    print("- Entity A: \(a.name), components: \(a.components)")
                       //  print("- Entity B: \(b.name), components: \(b.components)")

                         // Check for bet zone trigger
                         let names = [a.name, b.name]
                         guard names.contains("betZoneTrigger") else { return }

                        let chip = a.name == "betZoneTrigger" ? b : a

                           // Check for value component
                        guard var chipData = chip.components[PokerChipModelComponenet.self] as? PokerChipModelComponenet else { return }
                           // Prevent duplicate adds
                        guard chipData.hasBeenCounted == false else { return }
                           // Process the chip
                        print("💰 Chip: \(chip.name), +\(chipData.chipValue)")
                        handlePlayerBet(chipValue: chipData.chipValue)
                           //currentPot += chipData.value
                           // Mark it as counted and update the component
                        chipData.hasBeenCounted = true
                        chip.components.set(chipData)
                        game?.renderer.updateChips(addedChip: chip)
                     }

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
                    
                    else if value.entity.name == "bettingReadyCheck" {
                        handleReadyCheck()
                    }
                    
                    else if value.entity.name == "hitButton" {
                        handleHitButton()
                    }
                    else if value.entity.name == "standButton" {
                        handleStandButton()
                    }
                    else if value.entity.name == "greenChipStack_Element" {
                        Task {
                            await spawnChip(at: value.location3D, relativeTo: value.entity, tappedChipColor: "green")
                        }
                    }
                    else if value.entity.name == "redChipStack_Element" {
                        Task {
                            await spawnChip(at: value.location3D, relativeTo: value.entity, tappedChipColor: "red")
                        }
                    }
                    else if value.entity.name == "blueChipStack_Element" {
                        Task {
                        
                            await spawnChip(at: value.location3D, relativeTo: value.entity, tappedChipColor: "blue")
                        }
                    }
                
                })
                
                .gesture(
                    
                    DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .targetedToAnyEntity()
                    .onChanged { value in
                        guard value.entity.name.starts(with: "chip") else { return }
                        
                        let chip = value.entity
                        
                        // Convert location3D to world space
                        let handWorldPosition = value.convert(value.location3D, from: .local, to: .scene)
                        
                        // Compute offset once on first frame
                        if self.initialOffsetFromChipToTouch == nil {
                            let chipWorldPosition = chip.position(relativeTo: nil)
                            self.initialOffsetFromChipToTouch = chipWorldPosition - handWorldPosition
                            
                            // Set to kinematic mode for dragging
                            if var body = chip.components[PhysicsBodyComponent.self] {
                                body.mode = .kinematic
                                chip.components.set(body)
                            }
                        }
                        
                        // Drag movement
                        if let offset = self.initialOffsetFromChipToTouch {
                            let newPosition = handWorldPosition + offset
                            chip.setPosition(newPosition, relativeTo: nil)
                        }
                        
                    }
                    .onEnded { value in
                     //To place at the end
                        guard value.entity.name.starts(with: "chip") else {return}
                        print("regular ended")
                        let chip = value.entity
                        self.initialOffsetFromChipToTouch = nil
                        
                        if var physicsBody = chip.components[PhysicsBodyComponent.self] {
                            physicsBody.mode = .dynamic
                            physicsBody.linearDamping = 0.5
                            physicsBody.angularDamping = 0.5
                            
                            chip.components.set(physicsBody)
                            
                        }

                    }
                    
                )
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
            if game == nil { // Only initialize if not already done
                 print("GameTopView: Task started. Initializing BlackJackGame...")
                 let initializedGame = await BlackJackGame()
                 self.game = initializedGame
                 self.activityManager = GroupActivityManager(tabletopGame: initializedGame.tabletopGame)
                 print("GameTopView: BlackJackGame and ActivityManager initialized.")
            }
        }
    }

    // --- Action Functions ---
    private func handleStartButtonTap() {
        print("GameTopView: Start Button Tapped!")
        game?.startGameFromLobby()
        
    }
    private func spawnChip(at position3D: Point3D, relativeTo reference: Entity,tappedChipColor: String) async {
        print("GameTopView 🔭: starting the spawnChip task")
        var newChip = game?.createPokerChip(at: position3D, relativeTo: reference, tappedChipColor: tappedChipColor)
        
    }
    
    
    private func handleReadyCheck() {
        game?.handleReadyPlayers()
        game?.renderer.removeNoneBettingChips()
    }
    
    private func handleHitButton() {
        game?.playerDidHit()
        print("GameTopView: Adding Hit card to player")
    }
    
    private func handlePlayerBet(chipValue: Int) {
        game?.blackjackLogic.placeBet(playerId: game!.tabletopGame.localPlayer.id.uuid.uuidString, amount: chipValue)
    }

    private func handleStandButton() {
        game?.playerDidStand()
        
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
     // ← only builds for visionOS previews


