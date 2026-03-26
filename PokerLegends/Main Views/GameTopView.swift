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
    @Environment(\.openWindow) private var openWindow

    // Game state managed by BlackJackGame
    @State private var game: BlackJackGame? // Use specific type if possible
    @State private var activityManager: GroupActivityManager?
    @State private var hoverSub: Cancellable?
    @State private var initialOffsetFromChipToTouch: SIMD3<Float>? = nil
    @EnvironmentObject var session: GameSession
    @EnvironmentObject var userModel: UserModel



    // Name matching the entities in your Reality Composer Pro scene
    let startButtonName = "White_Play_Final"
    let closeButtonName = "Red_Quit_Final" // Added for the close button

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

                         let names = [a.name, b.name]
                         guard names.contains("betZoneTrigger") else { return }

                        let chip = a.name == "betZoneTrigger" ? b : a

                           // Check for value component
                        guard var chipData = chip.components[PokerChipModelComponenet.self] as? PokerChipModelComponenet else { return }
                           // Prevent duplicate adds
                        guard chipData.hasBeenCounted == false else { return }
                           // Process the chip
                        print("💰 Chip: \(chip.name), +\(chipData.chipValue)")
                        //function handling
                        makeChipNonInteractive(chip)
                        game?.renderer.showMoneyPopup(amount: chipData.chipValue)
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
                    
                    else if value.entity.name == "Green_Ready_Check" {
                        handleReadyCheck()
                    }
                    
                    else if value.entity.name == "hitButton" {
                        handleHitButton()
                    }
                    else if value.entity.name == "standButton" {
                        handleStandButton()
                    }
                    else if value.entity.name == "White_doubledown_Final" {
                        handleDoubleDown()
                    }
                    else if value.entity.name == "White_split_Final" {
                        handleSplitButton()
                    }
                    // Add new entity handlers for separate windows
                    else if value.entity.name == "menuButton" {
                        openGameMenu()
                    }
                    else if value.entity.name == "statsButton" {
                        openWindow(id: "game-stats")
                    }
                    else if value.entity.name == "profileButton" {
                        openWindow(id: "player-profile")
                    }
                    else if value.entity.name == "settingsButton" {
                        openWindow(id: "game-settings")
                    }
                    else if value.entity.name == "Green_Stack_Final" {
                        Task {
                            await spawnChip(at: value.location3D, relativeTo: value.entity, tappedChipColor: "green")
                        }
                    }
                    else if value.entity.name == "Red_Stack_Final" {
                        Task {
                            await spawnChip(at: value.location3D, relativeTo: value.entity, tappedChipColor: "red")
                        }
                    }
                    else if value.entity.name == "Blue_Stack_Final1" {
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
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack {
                            // Show sync status
                        }
                    }
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
                let initializedGame = await BlackJackGame(numberOfDecks: session.settings.numberOfDecks, userModel: userModel)
                 self.game = initializedGame
                 self.activityManager = GroupActivityManager(tabletopGame: initializedGame.tabletopGame)
                 print("GameTopView: BlackJackGame and ActivityManager initialized.")
            }
            
            // Setup CloudKit tracking for UserModel
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
    
    private func checkIfPlayerHasEnoughMoneyToPlaceBet(_ betAmount: Int) -> Bool {
        guard let playerMoney = userModel.playerMoney else { return false }
        return playerMoney >= Double(betAmount)
    }
    
    private func makeChipNonInteractive(_ chip: Entity) {
        chip.components.remove(InputTargetComponent.self)
        
        if var physicsBody = chip.components[PhysicsBodyComponent.self] {
            physicsBody.mode = .static
            chip.components.set(physicsBody)
        }
        print("🔒 Chip \(chip.name) is now non-interactive")
    }
    
    
    private func handleReadyCheck() {
        game?.handleReadyPlayers()
        game?.renderer.removeNoneBettingChips()
    }
    private func handleDoubleDown() {
        game?.playerDoubleDown()
        print("GameTopView: Double down")
    }
    
    private func handleSplitButton() {
        game?.playerSplitHand()
        print("GameTopView: Split Hand")
    }
    
    private func handleHitButton() {
        game?.playerDidHit()
        print("GameTopView: Adding Hit card to player")
    }
    
    private func handlePlayerBet(chipValue: Int) {
        let betAmounts = Double(chipValue)
        if checkIfPlayerHasEnoughMoneyToPlaceBet(chipValue) {
            game?.blackjackLogic.placeBet(
                playerId: game!.tabletopGame.localPlayer.id.uuid.uuidString,
                amount: chipValue
            )
        } else {
            showInsufficientFundsError()
        }
        // Place the bet in game logic
        
        print("💰 Bet placed: $\(chipValue).")
    }
    
    /// Show error when player doesn't have sufficient funds
    private func showInsufficientFundsError() {
        // You can implement this as an alert, toast, or other UI feedback
        print("❌ Insufficient funds for this bet!")
        // TODO: Implement proper error UI
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
    
    private func openGameMenu() {
        print("GameTopView: Opening in-game menu window")
        openWindow(id: "game-menu")
    }
}
     // ← only builds for visionOS previews


