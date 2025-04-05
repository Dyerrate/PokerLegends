//
//  BlackJackGame.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 10/6/24.
//
//  BlackJackGame.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 10/6/24.
//
//
//  BlackJackGame.swift

//
import TabletopKit
import RealityKit
import SwiftUI
import Combine
import Foundation // For UUID

@Observable
@MainActor
class BlackJackGame: @preconcurrency GameProtocol {

    // --- Properties ---
    let tabletopGame: TabletopGame
    let renderer: GameRenderer
    let observer: GameObserver
    let setup: GameSetup

    private(set) var blackjackLogic: BlackjackLogicController
    private var cancellables = Set<AnyCancellable>()

    // Card mapping state
    private var logicCardToEquipmentId: [UUID: EquipmentIdentifier] = [:]
    private var equipmentIdToLogicCard: [EquipmentIdentifier: UUID] = [:]
    private var nextCardEquipmentIdCounter: Int = 2000

    // Game readiness state
    private(set) var isReadyToStartFromLobby: Bool = false

    // --- Initialization ---
    init() async {
        print("BlackJackGame: Initializing...")
        // Initialize components
        blackjackLogic = BlackjackLogicController(numberOfDecks: 6)
        renderer = GameRenderer(typeOfGame: "blackJack") // Renderer first
        setup = GameSetup(root: renderer.root, currentGame: "blackJack") // Then setup
        tabletopGame = TabletopGame(tableSetup: setup.setup) // Then TabletopGame
        observer = GameObserver(tabletop: tabletopGame, renderer: renderer, gameToRender: "blackJack") // Then Observer

        // Add delegates/observers
        tabletopGame.addRenderDelegate(renderer)
        tabletopGame.addObserver(observer)

        // Assign cross-references
        renderer.blackJackGame = self
        renderer.gameSetup = setup // Give renderer access to setup info if needed

        // --- Load Scenes and Setup References ---
        // This needs to happen before setting up players or bindings
        await renderer.setupScenesAndReferences() // Await scene loading

        // Setup Combine bindings AFTER renderer setup
        setupBindings()

        // Setup initial player state and show lobby
        await setupInitialPlayerAndWait()
        print("BlackJackGame: Initialization complete. Lobby should be visible.")
    }

    // --- Setup player and wait in lobby ---
    private func setupInitialPlayerAndWait() async {
         print("BlackJackGame: Setting up initial player...")
         
         // First check if player already has a seat
         if let existingSeat = observer.seat(for: tabletopGame.localPlayer) {
             print("BlackJackGame: Player already has seat \(existingSeat.rawValue)")
             isReadyToStartFromLobby = true
             renderer.showLobbyScene()
             return
         }
         
         // Try to claim a seat
         print("BlackJackGame: Attempting to claim any seat...")
         await tabletopGame.claimAnySeat()
         
         // Wait a bit longer for the seat claim to process
         try? await Task.sleep(for: .milliseconds(500))
         
         // Check if seat was claimed
         if let claimedSeat = observer.seat(for: tabletopGame.localPlayer) {
             let localPlayerIdString = tabletopGame.localPlayer.id.uuid.uuidString
             blackjackLogic.addPlayer(playerId: localPlayerIdString)
             print("BlackJackGame: Successfully claimed seat \(claimedSeat.rawValue). Local player added with ID \(localPlayerIdString)")
             isReadyToStartFromLobby = true
             renderer.showLobbyScene()
             print("BlackJackGame: Ready to start from lobby. Showing lobby scene.")
         } else {
             print("BlackJackGame: ERROR - Failed to claim any seat. Available seats: \(setup.seats.count)")
             print("BlackJackGame: Current seat mappings: \(observer.playerSeats)")
             isReadyToStartFromLobby = false
             renderer.showLobbyScene() // Show lobby anyway, but start might not work
         }
    }

    // --- Start game from lobby ---
    func startGameFromLobby() {
        print("BlackJackGame: startGameFromLobby called.")
        guard isReadyToStartFromLobby else {
            print("BlackJackGame: Not ready to start from lobby yet.")
            return
        }
        // Only start if waiting or round is over
        guard blackjackLogic.gameState == .waitingForPlayers || blackjackLogic.gameState == .roundOver else {
             print("BlackJackGame: Cannot start from lobby. Current state: \(blackjackLogic.gameState)")
             return
        }

        print("BlackJackGame: Switching to main game scene and starting round...")
        isReadyToStartFromLobby = false

        // --- Show Main Game Scene ---
        renderer.showMainGameScene()

        // Start the actual game logic round
        startRound()
    }


    // --- Game Actions ---
    func startRound() {
        guard blackjackLogic.gameState == .waitingForPlayers || blackjackLogic.gameState == .roundOver else {
            print("BlackJackGame: Cannot start new round. Current state: \(blackjackLogic.gameState)")
            return
        }
        print("BlackJackGame: Starting new round logic...")
        // Ensure main game scene is visible when a round starts/restarts
        renderer.showMainGameScene()
        renderer.removeAllCardEntities()
        logicCardToEquipmentId.removeAll()
        equipmentIdToLogicCard.removeAll()
        blackjackLogic.startNewRound()
    }

    func playerDidHit() {
        guard case .playerTurn(let currentPlayerId) = blackjackLogic.gameState else { return }
        let localPlayerIdString = tabletopGame.localPlayer.id.uuid.uuidString
        if currentPlayerId == localPlayerIdString {
            print("BlackJackGame: Player Hits")
            blackjackLogic.playerAction(playerId: currentPlayerId, action: .hit)
        } else { print("BlackJackGame: Ignoring Hit action, not local player's turn.") }
    }

    func playerDidStand() {
         guard case .playerTurn(let currentPlayerId) = blackjackLogic.gameState else { return }
         let localPlayerIdString = tabletopGame.localPlayer.id.uuid.uuidString
         if currentPlayerId == localPlayerIdString {
             print("BlackJackGame: Player Stands")
             blackjackLogic.playerAction(playerId: currentPlayerId, action: .stand)
         } else { print("BlackJackGame: Ignoring Stand action, not local player's turn.") }
    }

    // --- State Observation and Rendering ---
    private func setupBindings() {
        print("BlackJackGame: Setting up bindings...")
        blackjackLogic.$gameState
            .receive(on: RunLoop.main)
            .sink { [weak self] newState in self?.handleGameStateChange(newState) }
            .store(in: &cancellables)

        // Bindings for hands and outcomes remain the same, triggering updateHandsVisuals/updateOutcomeVisuals
        blackjackLogic.$playerHands
             .receive(on: RunLoop.main)
             .sink { [weak self] hands in Task { await self?.updateHandsVisuals(playerHands: hands, dealerHand: self?.blackjackLogic.dealerHand ?? Hand()) } }
             .store(in: &cancellables)

        blackjackLogic.$dealerHand
             .receive(on: RunLoop.main)
             .sink { [weak self] hand in Task { await self?.updateHandsVisuals(playerHands: self?.blackjackLogic.playerHands ?? [:], dealerHand: hand) } }
             .store(in: &cancellables)

         blackjackLogic.$playerOutcomes
            .receive(on: RunLoop.main)
            .sink { [weak self] outcomes in self?.updateOutcomeVisuals(outcomes) }
            .store(in: &cancellables)
    }

    // --- Handle Game State Changes (Scene Switching Logic) ---
    private func handleGameStateChange(_ newState: BlackjackGameState) {
        print("BlackJackGame: Handling state change to \(newState)")
        // Default: disable action buttons
        renderer.setActionButtonsEnabled(false)
        // Optional: Unhighlight all player areas
        // for i in 0..<(setup.seats.count) { renderer.highlightPlayerArea(seatIndex: i, highlight: false) }

        switch newState {
            case .waitingForPlayers:
                 print("BlackJackGame: State -> Waiting")
                 // If waiting, likely means we should be in the lobby
                 renderer.showLobbyScene()
                 isReadyToStartFromLobby = true // Ready for next start

            case .betting:
                 print("BlackJackGame: State -> Betting")
                 // Ensure game scene is visible, handle betting UI
                 renderer.showMainGameScene()
                 // TODO: Implement betting visuals/interactions

            case .dealing:
                 print("BlackJackGame: State -> Dealing")
                 // Ensure game scene is visible
                 renderer.showMainGameScene()

            case .playerTurn(let playerId):
                print("BlackJackGame: State -> Player Turn: \(playerId)")
                // Ensure game scene is visible
                renderer.showMainGameScene()
                // Highlight active player and enable buttons if it's the local player
                if let seatIndex = getSeatIndex(for: playerId) { renderer.highlightPlayerArea(seatIndex: seatIndex, highlight: true) }
                if playerId == tabletopGame.localPlayer.id.uuid.uuidString { renderer.setActionButtonsEnabled(true) }

            case .dealerTurn:
                print("BlackJackGame: State -> Dealer Turn")
                // Ensure game scene is visible
                renderer.showMainGameScene()

            case .roundOver:
                 print("BlackJackGame: State -> Round Over")
                 // Ensure game scene is visible to show final hands/outcomes
                 renderer.showMainGameScene()
                 // After a delay, could switch back to lobby or show a "Play Again" button
                 // For now, stays in game scene. User can hit Reset or maybe Start in lobby again.
                 isReadyToStartFromLobby = true // Allow starting new round from lobby
                 // Example: Schedule return to lobby after 5 seconds
                 // Task {
                 //    try? await Task.sleep(for: .seconds(5))
                 //    // Check if state is still roundOver before switching
                 //    if self.blackjackLogic.gameState == .roundOver {
                 //        self.renderer.showLobbyScene()
                 //    }
                 // }
        }
    }

    // --- Update Visuals (Card dealing logic remains similar) ---
    private func updateHandsVisuals(playerHands: [String: Hand], dealerHand: Hand) async {
        // This function remains largely the same as before, dealing cards
        // using the transforms derived from markers in the main game scene.
        // Ensure it's only called/effective when the main game scene is active.
        guard renderer.mainGameSceneEntity?.isEnabled ?? false else {
            // print("BlackJackGame: Skipping hand update, main game scene not visible.")
            return // Don't update visuals if game scene isn't shown
        }

        print("BlackJackGame: Updating hand visuals (Main Game Scene active)...")
        var dealDelay: TimeInterval = 0.0
        let delayIncrement: TimeInterval = 0.15

        // --- Update Player Hands ---
        for (playerId, hand) in playerHands {
            guard let seatIndex = getSeatIndex(for: playerId) else { continue }
            for (cardIndex, card) in hand.cards.enumerated() {
                let equipmentId: EquipmentIdentifier
                if let existingId = logicCardToEquipmentId[card.id] {
                    equipmentId = existingId
                } else {
                    equipmentId = generateNextCardEquipmentId()
                    logicCardToEquipmentId[card.id] = equipmentId
                    equipmentIdToLogicCard[equipmentId] = card.id
                    guard let cardEntity = await renderer.findOrCreateCardEntity(for: equipmentId, cardData: card) else { continue }
                    let startTransform = renderer.getShoeTransform()
                    let endTransform = renderer.getTransformForPlayerCard(cardIndex: cardIndex, totalCardsInHand: hand.cards.count, seatIndex: seatIndex)
                    renderer.animateDealCard(cardEntity: cardEntity, from: startTransform, to: endTransform, faceUp: card.isFaceUp, delay: dealDelay)
                    dealDelay += delayIncrement
                }
            }
            // TODO: Remove visual cards no longer in this player's logical hand
        }

        // --- Update Dealer Hand ---
        for (cardIndex, card) in dealerHand.cards.enumerated() {
            let equipmentId: EquipmentIdentifier
             if let existingId = logicCardToEquipmentId[card.id] {
                 equipmentId = existingId
                 // Flip check
                 if cardIndex == 1 && card.isFaceUp {
                      if let cardEntity = renderer.cardEntities[equipmentId], cardEntity.orientation.isFaceDown {
                           renderer.animateFlipCard(cardEntity: cardEntity, faceUp: true)
                      }
                 }
             } else {
                  equipmentId = generateNextCardEquipmentId()
                  logicCardToEquipmentId[card.id] = equipmentId
                  equipmentIdToLogicCard[equipmentId] = card.id
                  guard let cardEntity = await renderer.findOrCreateCardEntity(for: equipmentId, cardData: card) else { continue }
                  let startTransform = renderer.getShoeTransform()
                  let endTransform = renderer.getTransformForDealerCard(cardIndex: cardIndex, totalCardsInHand: dealerHand.cards.count)
                  let isDealingPhase = blackjackLogic.gameState == .dealing
                  let isHoleCardBeingDealt = (cardIndex == 1 && isDealingPhase)
                  let dealFaceUp = !isHoleCardBeingDealt
                  renderer.animateDealCard(cardEntity: cardEntity, from: startTransform, to: endTransform, faceUp: dealFaceUp, delay: dealDelay)
                  dealDelay += delayIncrement
             }
        }
        // TODO: Remove visual cards no longer in dealer's logical hand
        print("BlackJackGame: Finished updating hand visuals.")
    }


    private func updateOutcomeVisuals(_ outcomes: [String: GameOutcome]) {
        // This remains the same - display text near player/dealer areas
        print("BlackJackGame: Updating outcome visuals...")
        // ... (implementation from previous version) ...
        for (playerId, outcome) in outcomes {
             guard let seatIndex = getSeatIndex(for: playerId) else { continue }
             let outcomeText: String
             switch outcome { /* ... cases ... */
                 case .playerBust: outcomeText = "Bust!"
                 case .dealerBust: outcomeText = "Win! (Dealer Bust)"
                 case .playerBlackjack: outcomeText = "Blackjack!"
                 case .dealerBlackjack: outcomeText = "Lose (Dealer BJ)"
                 case .playerWin: outcomeText = "Win!"
                 case .dealerWin: outcomeText = "Lose"
                 case .push: outcomeText = "Push"
             }
             print("Player \(playerId) (Seat \(seatIndex)) Outcome: \(outcomeText)") // Placeholder
             // renderer.updateStatusText(text: outcomeText, for: playerHandAreaId)
        }
        if blackjackLogic.dealerHand.isBusted { print("Dealer Outcome: Busts!") }
        else if blackjackLogic.gameState == .roundOver { print("Dealer Outcome: Stands with \(blackjackLogic.dealerHand.score)") }
    }


    // --- Utility ---
    private func generateNextCardEquipmentId() -> EquipmentIdentifier {
        let id = EquipmentIdentifier(nextCardEquipmentIdCounter)
        nextCardEquipmentIdCounter += 1
        return id
    }

    private func getSeatIndex(for playerId: String) -> Int? {
        for (index, seat) in setup.seats.enumerated() {
            if let occupantPlayerId = observer.playerId(in: seat.id),
               occupantPlayerId.uuid.uuidString == playerId {
                return index
            }
        }
        print("BlackJackGame: WARNING - Could not find seat index for player ID \(playerId)")
        return nil
    }


    // --- GameProtocol Conformance ---
    func resetGame() {
        print("BlackJackGame: Reset game called.")
        // --- MODIFIED Condition ---
        // Use pattern matching to check if the game is in a resettable state
        let currentState = blackjackLogic.gameState
        if case .roundOver = currentState {
             // If round is over, reset to waiting (shows lobby)
             print("Resetting to waiting state from roundOver.")
             blackjackLogic.resetToWaitingState() // Use the internal reset function
             // handleGameStateChange will be called via the binding to show lobby
        } else if case .playerTurn = currentState {
             // If it's a player's turn, reset to waiting
             print("Resetting to waiting state from playerTurn.")
             blackjackLogic.resetToWaitingState()
        } else if case .dealerTurn = currentState {
             // If it's the dealer's turn, reset to waiting
             print("Resetting to waiting state from dealerTurn.")
             blackjackLogic.resetToWaitingState()
        } else if case .dealing = currentState {
             // If dealing, reset to waiting
             print("Resetting to resetGamewaiting state from dealing.")
             blackjackLogic.resetToWaitingState()
        } else if case .betting = currentState {
             // If betting, reset to waiting
             print("Resetting to waiting state from betting.")
             blackjackLogic.resetToWaitingState()
        }
        else {
            // If already waiting, or some other state, do nothing or log
            print("BlackJackGame: Reset ignored, state is \(currentState).")
        }
    }

    // --- Cleanup function ---
    func cleanupBeforeDismiss() {
         print("BlackJackGame: Cleaning up before dismiss...")
         //tabletopGame.leave()
         renderer.cleanup() // Call renderer's cleanup
         print("BlackJackGame: Cancelling Combine subscriptions.")
         cancellables.forEach { $0.cancel() }
         cancellables.removeAll()
    }

    // --- Deinitialization ---
    deinit {
        print("BlackJackGame: Deinitializing. Cleanup should have happened in cleanupBeforeDismiss.")
    }
}


// Helper extension for SIMD Quaternions (Keep as is)
extension simd_quatf {
    var isFaceUp: Bool {
        let angle = self.angle
        let axis = self.axis
        return abs(axis.y) < 0.1 || abs(angle) < 0.1 || abs(angle - .pi * 2) < 0.1
    }
    var isFaceDown: Bool {
        let angle = self.angle
        let axis = self.axis
        return abs(axis.y - 1.0) < 0.1 && abs(angle - .pi) < 0.1
    }
}

