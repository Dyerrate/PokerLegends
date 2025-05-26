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
//
//  BlackJackGame.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 10/6/24.
//
//
//  BlackJackGame.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 10/6/24.
//
import TabletopKit
import RealityKit
import SwiftUI
import Combine // <-- Ensure Combine is imported
import Foundation

@Observable
@MainActor
class BlackJackGame: @preconcurrency GameProtocol {

    // Properties
    let tabletopGame: TabletopGame
    let renderer: GameRenderer
    let observer: GameObserver
    let setup: GameSetup
    
    private(set) var blackjackLogic: BlackjackLogicController
    private var cancellables = Set<AnyCancellable>() // Keep for other bindings
    private var logicCardToEquipmentId: [UUID: EquipmentIdentifier] = [:]
    private var equipmentIdToLogicCard: [EquipmentIdentifier: UUID] = [:]
    private var nextCardEquipmentIdCounter: Int = 2000
    private(set) var isReadyToStartFromLobby: Bool = false

    // Task handle for seat waiting cancellation
    var seatWaitTask: Task<Void, Never>? = nil


    // --- Initialization ---
    init() async {
        print("BlackJackGame: Initializing...")
        blackjackLogic = BlackjackLogicController(numberOfDecks: 6)
        renderer = GameRenderer(typeOfGame: "blackJack")
        setup = GameSetup(root: renderer.root, currentGame: "blackJack")
        tabletopGame = TabletopGame(tableSetup: setup.setup)
        // IMPORTANT: Observer must be initialized AFTER tabletopGame
        observer = GameObserver(tabletop: tabletopGame, renderer: renderer, gameToRender: "blackJack")
        tabletopGame.addRenderDelegate(renderer)
        tabletopGame.addObserver(observer) // Add observer AFTER it's initialized
        renderer.blackJackGame = self
        renderer.gameSetup = setup
        await renderer.setupScenesAndReferences()
        setupBindings() // Setup other bindings
        // Start the process to claim seat and wait
        // Use a Task to avoid blocking init if wait takes time, although init is already async
        seatWaitTask = Task {
             await setupInitialPlayerAndWait()
        }
        print("BlackJackGame: Initialization sequence complete. Waiting for seat claim task.")
    }

    // --- Setup player and wait in lobby ---
    private func setupInitialPlayerAndWait() async {
         print("BlackJackGame: Setting up initial player...")

         // Ensure observer is ready before proceeding (optional safety)
         // await Task.yield()

         // Use a Combine Future or similar pattern to wait for the subject
         let seatClaimedPublisher = observer.localPlayerSeatedSubject
             .first() // We only need the first confirmation
             .timeout(5.0, scheduler: DispatchQueue.main) // Wait max 5 seconds
             .map { _ in true } // Map success to true
             .replaceError(with: false) // Map timeout/error to false
             .eraseToAnyPublisher()

         // Call claimAnySeat - the observer callback will trigger the subject if successful
         await tabletopGame.claimAnySeat()
         print("BlackJackGame: Called claimAnySeat(). Waiting for observer event via Combine...")

         // Await the result from the publisher
         var seatClaimed = false
         let cancellable = seatClaimedPublisher.sink { claimed in
             seatClaimed = claimed
         }
         // We need to keep the subscription alive while waiting.
         // Since this function is async, we can loop briefly or use another mechanism.
         // Let's use a short async wait loop here, checking the flag set by the sink.
         let maxWaitTime = 5.5 // Slightly longer than timeout
         var waitTime: TimeInterval = 0
         let checkInterval = 0.05
         while waitTime < maxWaitTime && !seatClaimed {
              // Check if the sink has completed and set seatClaimed to true
              // The actual check happens implicitly via the !seatClaimed condition
              try? await Task.sleep(for: .seconds(checkInterval))
              waitTime += checkInterval
              // Need to yield to allow the sink closure to execute if event arrives
              await Task.yield()
         }
         cancellable.cancel() // Clean up subscription
         // Now check the final result
         if seatClaimed {
             let localPlayerIdString = tabletopGame.localPlayer.id.uuid.uuidString
             blackjackLogic.addPlayer(playerId: localPlayerIdString)
             print("BlackJackGame: Seat claimed confirmed by observer event. Local player added with ID \(localPlayerIdString)")
             isReadyToStartFromLobby = true
             renderer.showLobbyScene()
             print("BlackJackGame: Ready to start from lobby. Showing lobby scene.")
         } else {
             print("BlackJackGame: ERROR - Failed to claim seat (timed out waiting for observer event).")
             isReadyToStartFromLobby = false
             renderer.showLobbyScene()
         }
         seatWaitTask = nil // Clear task handle
    }

    // --- Start game from lobby ---
    // Remains the same
    func startGameFromLobby() {
        print("BlackJackGame: startGameFromLobby called.")
        guard isReadyToStartFromLobby else {
            print("BlackJackGame: Not ready to start from lobby yet (isReadyToStartFromLobby is false - likely seat not claimed).")
            return
        }
        guard blackjackLogic.gameState == .waitingForPlayers || blackjackLogic.gameState == .roundOver else {
             print("BlackJackGame: Cannot start from lobby. Current state: \(blackjackLogic.gameState)")
             return
        }
        print("BlackJackGame: Switching to main game scene and starting round...")
        isReadyToStartFromLobby = false
        renderer.showMainGameScene()
        startRound()
    }


    // --- Game Actions (startRound, playerDidHit, playerDidStand) ---
    // Remain the same
    func startRound() { /* ... */
        guard blackjackLogic.gameState == .waitingForPlayers || blackjackLogic.gameState == .roundOver else { return }
        print("BlackJackGame: Starting new round logic...")
        renderer.showMainGameScene()
        renderer.removeAllCardEntities()
        logicCardToEquipmentId.removeAll()
        equipmentIdToLogicCard.removeAll()
        blackjackLogic.startNewRound()
        setBettingEntityStart()
        
        Task { @MainActor in
                    // Give a tiny delay for the @Published properties to update if needed
                    try? await Task.sleep(for: .milliseconds(10))
                    print("BlackJackGame: Calling setInitialCardVisuals after startNewRound.")
                    await setInitalCardVisuals(playerHands: blackjackLogic.playerHands, dealerHand: blackjackLogic.dealerHand)
                }
     }
    
    func playerDidPlaceBet(amount: Int) {
            guard blackjackLogic.gameState == .betting else {
                print("BlackJackGame: Cannot place bet. Not in betting state. Current state: \(blackjackLogic.gameState)")
                return
            }
            let localPlayerIdString = tabletopGame.localPlayer.id.uuid.uuidString
            print("BlackJackGame: Player \(localPlayerIdString) attempts to bet \(amount)")
            blackjackLogic.placeBet(playerId: localPlayerIdString, amount: amount)

            // Visual update for the bet placed would happen here via GameRenderer
            if let seatIndex = getSeatIndex(for: localPlayerIdString) {
                // Task { await renderer.updateBetVisualForPlayer(playerId: localPlayerIdString, amount: amount, seatIndex: seatIndex) }
                 print("BlackJackGame: Bet placed by \(localPlayerIdString). UI should now allow 'Ready'.")
            }
            // DO NOT automatically call ready here. Player must explicitly tap the ready button.
        }
    
    func playerDidHit() { /* ... */
        guard case .playerTurn(let currentPlayerId) = blackjackLogic.gameState,
              currentPlayerId == tabletopGame.localPlayer.id.uuid.uuidString else { return }
        print("BlackJackGame: Player Hits")
        blackjackLogic.playerAction(playerId: currentPlayerId, action: .hit)
     }
    
    func playerDidStand() { /* ... */
         guard case .playerTurn(let currentPlayerId) = blackjackLogic.gameState,
               currentPlayerId == tabletopGame.localPlayer.id.uuid.uuidString else { return }
         print("BlackJackGame: Player Stands")
         blackjackLogic.playerAction(playerId: currentPlayerId, action: .stand)
     }

     // Remain the same
    private func setupBindings() {
         print("BlackJackGame: Setting up bindings...")
         let debounceInterval: RunLoop.SchedulerTimeType.Stride = .milliseconds(100) // Keep debounce

         // --- GameState and Outcomes subscriptions remain the same ---
         blackjackLogic.$gameState
             .receive(on: RunLoop.main)
             .sink { [weak self] newState in self?.handleGameStateChange(newState) }
             .store(in: &cancellables)

         blackjackLogic.$playerOutcomes
             .receive(on: RunLoop.main)
             .sink { [weak self] outcomes in self?.updateOutcomeVisuals(outcomes) }
             .store(in: &cancellables)
        
        blackjackLogic.$playerBets
                    .debounce(for: debounceInterval, scheduler: RunLoop.main)
                    .receive(on: RunLoop.main)
                    .sink { [weak self] bets in
                        // guard let self = self else { return } // 'self' is not used here currently
                        print("[Combine Bindings] Player bets updated: \(bets).")
                        // Task { await self.updateAllBetVisuals(bets: bets) } // If you have this function
                    }
                    .store(in: &cancellables)

                // New binding to observe changes in playersReadyAfterBetting if needed for UI updates
                blackjackLogic.$playersReadyAfterBetting
                    .receive(on: RunLoop.main)
                    .sink { [weak self] readyPlayers in
                        print("[Combine Bindings] Ready players updated: \(readyPlayers).")
                        // You could update UI here to show which players are ready,
                        // e.g., by iterating through readyPlayers and updating their ready indicators.
                        // for playerId in readyPlayers {
                        //    if let seatIndex = self?.getSeatIndex(for: playerId) {
                        //        self?.renderer.updatePlayerReadyIndicator(seatIndex: seatIndex, isReady: true)
                        //    }
                        // }
                        // Also handle players who might un-ready (if you add that feature)
                    }
                    .store(in: &cancellables)

         // --- Combine Player & Dealer Hand Publishers ---
         Publishers.CombineLatest(blackjackLogic.$playerHands, blackjackLogic.$dealerHand)
             .debounce(for: debounceInterval, scheduler: RunLoop.main) // Keep debounce
             .receive(on: RunLoop.main)
             .sink { [weak self] (latestPlayerHands, latestDealerHand) in
                 guard let self = self else { return }

                 // --- REVISED LOGIC ---
                 let currentState = self.blackjackLogic.gameState
                 print("[Combine Bindings] Hand update received. Current State: \(currentState)")

                 Task { @MainActor in
                     // 1. Always try to add visuals for any *new* cards whenever hands change.
                     //    `addCardsMidGame` checks internally if a card is already visualized.
                     //    This ensures the bust card visual is added even if state changes quickly.
                     print("[Combine Bindings] Calling addCardsMidGame to sync visuals...")
                     await self.addCardsMidGame(playerHands: latestPlayerHands, dealerHand: latestDealerHand)

                     // 2. Handle additional state-specific visual updates *after* syncing new cards.
                     switch currentState {
                     case .dealing:
                         // Initial visuals are now handled in startRound.
                         // This case might only be needed if dealing involves animations delayed over time.
                         print("[Combine Bindings] State is .dealing. Visuals likely handled initially.")
                         // If dealing has complex steps, add logic here.
                         break // Explicitly do nothing extra for now

                     case .playerTurn:
                         // `addCardsMidGame` already handled adding new cards.
                         print("[Combine Bindings] State is active turn. New cards synced.")
                         break // Explicitly do nothing extra
                         
                     case .dealerTurn:
                         print("[Combine Bindings] State dealerTurn. New cards synced.")


                     case .roundOver:
                         // Ensure the dealer's hole card is visually flipped if needed.
                         print("[Combine Bindings] State is .roundOver. Ensuring dealer hole card flipped.")
                         

                     case .waitingForPlayers, .betting:
                         // No specific hand visual updates typically needed here.
                         print("[Combine Bindings] Hand update received in state \(currentState). No extra visual action needed.")
                     }
                 }
                 // --- End of Revised Logic ---
             }
             .store(in: &cancellables)
     }
    
    private func addCardsMidGame(playerHands: [String: Hand], dealerHand: Hand) async {
        guard renderer.mainGameSceneEntity?.isEnabled ?? false else {
            print("[addCardsMidGame] Main game scene not active. Skipping.")
            return
        }
         print("[addCardsMidGame] Checking for new cards to add...")
        // --- Player Hands ---
        for (playerId, hand) in playerHands {
            guard let seatIndex = getSeatIndex(for: playerId) else { continue }
            // Iterate through cards in the hand
            for (cardIndex, card) in hand.cards.enumerated() {
                // Check if this card ALREADY has a visual representation
                if logicCardToEquipmentId[card.id] == nil {
                    // --- This is a NEW card ---
                    print("[addCardsMidGame] Found NEW card for Player \(playerId) (Seat \(seatIndex)): \(card.description) at index \(cardIndex)")
                    // Generate ID and create mapping
                    let equipmentId = generateNextCardEquipmentId()
                    logicCardToEquipmentId[card.id] = equipmentId
                    equipmentIdToLogicCard[equipmentId] = card.id
                    print("  Mapping Card \(card.description) (ID: \(card.id)) to EquipmentID \(equipmentId.rawValue)")

                    // Find/Create Entity
                    guard let cardEntity = await renderer.findOrCreateCardEntity(for: equipmentId, cardData: card) else {
                        print("  ERROR: Failed to find/create entity for NEW Player Card. Skipping.")
                        continue
                    }
                    // Generate Template Clone & Add to Scene
                    // The card data should have isFaceUp=true when dealt mid-game
                    let cloneCardFromTemplate = renderer.generateCardTemplateEntity(currentCardEntity: cardEntity)
                    renderer.addPlayerCard(currentCard: cloneCardFromTemplate, playerSeat: seatIndex, cardIndex: cardIndex)
                    print("  Added visual for NEW Player Card \(cardIndex) (\(card.description))")
                }
            }
        }

        // --- Dealer Hand ---
        // Dealer usually only gets cards during their turn after players finish
        for (cardIndex, card) in dealerHand.cards.enumerated() {
            // Check if this card ALREADY has a visual representation
            if logicCardToEquipmentId[card.id] == nil {
                 // --- This is a NEW card (likely revealed hole card or hit card) ---
                 print("[addCardsMidGame] Found NEW card for Dealer: \(card.description) at index \(cardIndex)")

                 // Generate ID and create mapping
                 let equipmentId = generateNextCardEquipmentId()
                logicCardToEquipmentId[card.id] = equipmentId
                equipmentIdToLogicCard[equipmentId] = card.id
                 print("  Mapping Card \(card.description) (ID: \(card.id)) to EquipmentID \(equipmentId.rawValue)")

                 // Find/Create Entity
                 guard let cardEntity = await renderer.findOrCreateCardEntity(for: equipmentId, cardData: card) else {
                     print("  ERROR: Failed to find/create entity for NEW Dealer Card. Skipping.")
                     continue
                 }
                 // Generate Template Clone & Add to Scene
                 // Ensure the card is face up visually when added mid-turn
                 let cloneCardFromTemplate = renderer.generateCardTemplateEntity(currentCardEntity: cardEntity)
                 // --- Special Handling for Dealer's Hole Card Reveal ---
                 // If this is the second card (index 1) and it *was* face down in the logic but now needs visual update
                 if cardIndex == 1 && !card.isFaceUp {
                     // The logic controller should have flipped isFaceUp=true before this point.
                     // We might need an explicit flip animation call here if addDealerCard doesn't handle it.
                     // For now, assume addDealerCard places it correctly based on card.isFaceUp.
                     print("  Dealer hole card (\(card.description)) is being added/updated visually.")
                 }
                 renderer.addDealerCard(currentCard: cloneCardFromTemplate, cardIndex: cardIndex)
                 print("  Added visual for NEW Dealer Card \(cardIndex) (\(card.description)), faceUp=\(card.isFaceUp)")
            }
        }
         print("[addCardsMidGame] Finished checking for new cards.")
    }
    private func handleGameStateChange(_ newState: BlackjackGameState) {
        print("BlackJackGame: Handling state change to \(newState)")
        renderer.setActionButtonsEnabled(false) // Disable buttons by default
        switch newState {
            case .waitingForPlayers:
                renderer.showLobbyScene()
                isReadyToStartFromLobby = true // Allow starting from lobby again
            case .betting:
                renderer.showMainGameScene()
                // TODO: Enable betting controls if implemented
            case .dealing:
                renderer.showMainGameScene()
                // Visuals handled by Combine binding + startRound calling setInitialCardVisuals
            case .playerTurn(let playerId):
                renderer.showMainGameScene()
                // Highlight active player
                if let seatIndex = getSeatIndex(for: playerId) {
                    renderer.highlightPlayerArea(seatIndex: seatIndex, highlight: true)
                }
                // Enable Hit/Stand only for the local player whose turn it is
                if playerId == tabletopGame.localPlayer.id.uuid.uuidString {
                    // Check if player is already busted - don't enable if busted
                    if blackjackLogic.playerOutcomes[playerId] == nil { // Only enable if no outcome yet
                        renderer.setActionButtonsEnabled(true)
                    }
                }
            case .dealerTurn:
            print("THIS DEALERTURN1")
                renderer.revealDealerHoleCard()

            case .roundOver:
                renderer.showMainGameScene()
                isReadyToStartFromLobby = true // Allow starting next round via lobby button

        }
     }
    
    func createPokerChip(at position3D: Point3D, relativeTo reference: Entity,tappedChipColor: String) {
        print("BlackJackGame🎲: Startin createPokerChip ")
        renderer.spawnPokerChip(at: position3D, relativeTo: reference, tappedChipColor: tappedChipColor)
    }
    
    
   
    private func setInitalCardVisuals(playerHands: [String: Hand], dealerHand: Hand) async {
        guard renderer.mainGameSceneEntity?.isEnabled ?? false else { return }
        //INFO: PLAYER HAND loop for each player
        for (playerId, hand) in playerHands {
            guard let seatIndex = getSeatIndex(for: playerId) else { continue }
            //INFO: Looping through each card per hand
            for (cardIndex, card) in hand.cards.enumerated() {
                let equipmentId = logicCardToEquipmentId[card.id] ?? generateNextCardEquipmentId()
                if logicCardToEquipmentId[card.id] == nil {
                    print("BlackJackGame: Assigning the card to the player")
                    
                    guard let cardEntity = await renderer.findOrCreateCardEntity(for: equipmentId, cardData: card) else {
                        print("  [BJGame Debug] ERROR: Failed to find/create entity for Dealer Card \(cardIndex). Skipping.")
                        continue // Skip if entity creation fails
                    }
                    let cloneCardFromTemplate = renderer.generateCardTemplateEntity(currentCardEntity: cardEntity)
                    renderer.addPlayerCard(currentCard: cloneCardFromTemplate, playerSeat: seatIndex, cardIndex: cardIndex)
                    
                }
            }

        }
        
        
        //TODO: DEALER HAND loop for each card
        for (cardIndex, card) in dealerHand.cards.enumerated() {
            print("BlackJackGame: Assigning the card to the dealer")
            
            let equipmentId = logicCardToEquipmentId[card.id] ?? generateNextCardEquipmentId()
            if logicCardToEquipmentId[card.id] == nil {
                logicCardToEquipmentId[card.id] = equipmentId
                equipmentIdToLogicCard[equipmentId] = card.id
                
                
                guard let cardEntity = await renderer.findOrCreateCardEntity(for: equipmentId, cardData: card) else {
                    print("  [BJGame Debug] ERROR: Failed to find/create entity for Dealer Card \(cardIndex). Skipping.")
                    continue // Skip if entity creation fails
                }
                let cloneCardFromTemplate = renderer.generateCardTemplateEntity(currentCardEntity: cardEntity)
                renderer.addDealerCard(currentCard: cloneCardFromTemplate, cardIndex: cardIndex)
            }
        }

    }
    
    private func updateOutcomeVisuals(_ outcomes: [String: GameOutcome]) { /* ... */
        print("BlackJackGame: Updating outcome visuals...")
        for (playerId, outcome) in outcomes {
             guard let seatIndex = getSeatIndex(for: playerId) else { continue }
             let outcomeText: String
             switch outcome {
                 case .playerBust: outcomeText = "Bust!"; case .dealerBust: outcomeText = "Win! (Dealer Bust)"; case .playerBlackjack: outcomeText = "Blackjack!"; case .dealerBlackjack: outcomeText = "Lose (Dealer BJ)"; case .playerWin: outcomeText = "Win!"; case .dealerWin: outcomeText = "Lose"; case .push: outcomeText = "Push"
             }
             print("Player \(playerId) (Seat \(seatIndex)) Outcome: \(outcomeText)")
        }
        if blackjackLogic.dealerHand.isBusted { print("Dealer Outcome: Busts!") }
        else if blackjackLogic.gameState == .roundOver { print("Dealer Outcome: Stands with \(blackjackLogic.dealerHand.score)") }
     }


    // --- Utility ---
    private func generateNextCardEquipmentId() -> EquipmentIdentifier { /* ... */
        let id = EquipmentIdentifier(nextCardEquipmentIdCounter); nextCardEquipmentIdCounter += 1; return id
     }
    private func getSeatIndex(for playerId: String) -> Int? { /* ... */
        for (index, seat) in setup.seats.enumerated() {
            if let occupantPlayerId = observer.playerId(in: seat.id), occupantPlayerId.uuid.uuidString == playerId { return index }
        }
        print("BlackJackGame: WARNING - Could not find seat index for player ID \(playerId)"); return nil
     }


    // --- GameProtocol Conformance (resetGame) ---
     // remains the same
    func resetGame() { /* ... */
        print("BlackJackGame: Reset game called.")
        let currentState = blackjackLogic.gameState
        if case .roundOver = currentState { blackjackLogic.resetToWaitingState() }
        else if case .playerTurn = currentState { blackjackLogic.resetToWaitingState() }
        else if case .dealerTurn = currentState { blackjackLogic.resetToWaitingState() }
        else if case .dealing = currentState { blackjackLogic.resetToWaitingState() }
        else if case .betting = currentState { blackjackLogic.resetToWaitingState() }
        else { print("BlackJackGame: Reset ignored, state is \(currentState).") }
     }
    
    func addHitCardToPlayer() {
        
    }
    
    func playerDidTapReadyButton() {
            guard blackjackLogic.gameState == .betting else {
                print("BlackJackGame: Cannot tap 'Ready'. Not in betting state. Current state: \(blackjackLogic.gameState)")
                return
            }
            let localPlayerIdString = tabletopGame.localPlayer.id.uuid.uuidString
            guard (blackjackLogic.playerBets[localPlayerIdString] ?? 0) > 0 else {
                print("BlackJackGame: Player \(localPlayerIdString) must place a bet before tapping 'Ready'.")
                // Optionally provide UI feedback here (e.g., an alert or disabling the ready button)
                return
            }

            print("BlackJackGame: Player \(localPlayerIdString) tapped 'Ready' button.")
            blackjackLogic.playerReadyAfterBetting(playerId: localPlayerIdString)

            // Optionally, GameRenderer can update the 'Ready' button's appearance (e.g., show a checkmark)
            // if let seatIndex = getSeatIndex(for: localPlayerIdString) {
            //     renderer.updatePlayerReadyIndicator(seatIndex: seatIndex, isReady: true)
            // }
        }
    
    func setBettingEntityStart() {
        renderer.setBettingSettingStart()
    }


    // --- Cleanup function ---
    func cleanupBeforeDismiss() { /* ... */
         print("BlackJackGame: Cleaning up before dismiss...")
         seatWaitTask?.cancel() // Cancel the wait task if it's still running
         seatWaitTask = nil
        // tabletopGame.leave()
         renderer.cleanup()
         print("BlackJackGame: Cancelling Combine subscriptions.")
         cancellables.forEach { $0.cancel() }
         cancellables.removeAll()
     }

    // --- Deinitialization ---
    deinit { /* ... */
        print("BlackJackGame: Deinitializing. Cleanup should have happened in cleanupBeforeDismiss.")
        // Ensure task is cancelled on deinit as a safeguard
      //  seatWaitTask?.cancel()
     }
}

