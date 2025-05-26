//
//  BlackjackLogicController.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 4/1/25.
//
import Foundation
import Combine // Using Combine to publish state changes

// Defines the possible states of a Blackjack game round.
enum BlackjackGameState: Codable, Equatable {
    case betting        // Players are placing bets
    case dealing        // Initial hands are being dealt
    case playerTurn(playerId: String) // A specific player's turn to act
    case dealerTurn     // Dealer is playing their hand
    case roundOver      // Round finished, outcomes determined
    case waitingForPlayers // Waiting for players to join or ready up

    // Swift automatically synthesizes Equatable conformance because String is Equatable.
    // No need to write static func ==(...) manually here.
}

// Defines the possible actions a player can take.
enum PlayerAction: Codable {
    case hit
    case stand
    // TODO: Add Double Down, Split, Insurance later if desired
}

// Defines the outcome of a round for a player.
enum GameOutcome: Codable {
    case playerBust
    case dealerBust
    case playerBlackjack
    case dealerBlackjack
    case playerWin
    case dealerWin
    case push // Tie
}

// Manages the core logic and state of a Blackjack game.
// This class is independent of UI and TabletopKit.
class BlackjackLogicController: ObservableObject {

    // --- Published Properties (for Combine subscribers like BlackJackGame) ---
    @Published private(set) var gameState: BlackjackGameState = .waitingForPlayers
    @Published private(set) var dealerHand = Hand()
    @Published private(set) var playerHands: [String: Hand] = [:] // Player ID -> Hand
    @Published private(set) var playerBets: [String: Int] = [:]   // Player ID -> Bet Amount
    @Published private(set) var playerOutcomes: [String: GameOutcome] = [:] // Player ID -> Outcome
    @Published private(set) var deck: [PlayingCard] = []
    @Published private(set) var activePlayerIds: [String] = [] // IDs of players in the current round
    @Published private(set) var playersReadyAfterBetting: Set<String> = []
    @Published private(set) var allPlayersHaveBet: Bool = false

    // --- Private Properties ---
    private var shoe: [PlayingCard] = [] // Cards to be dealt from
    private let numberOfDecks: Int // How many decks to use in the shoe
    private var currentPlayerIndex: Int = 0

    // --- Initialization ---
    init(numberOfDecks: Int = 6) {
        self.numberOfDecks = numberOfDecks
        // Initial state setup can happen here or when players join
    }

    // --- Player Management ---

    /// Adds a player to the game.
    /// - Parameter playerId: A unique identifier for the player.
    func addPlayer(playerId: String) {
            guard playerHands[playerId] == nil else { return } // Don't add if already exists
            playerHands[playerId] = Hand()
            playerBets[playerId] = 0 // Initialize bet
            playerOutcomes[playerId] = nil
            activePlayerIds.append(playerId) // Add to active list for the round
            print("Player \(playerId) added.")

            // --- Corrected Line ---
            // Use 'if case' for pattern matching instead of '=='
            if case .waitingForPlayers = gameState, !activePlayerIds.isEmpty {
                 // Maybe transition to betting automatically, or wait for a "start" action
                 // For now, let's assume we need to manually start the round
                 print("Player added while waiting. Consider transitioning state.")
            }
        }

    /// Removes a player from the game.
    /// - Parameter playerId: The identifier of the player to remove.
    func removePlayer(playerId: String) {
        playerHands.removeValue(forKey: playerId)
        playerBets.removeValue(forKey: playerId)
        playerOutcomes.removeValue(forKey: playerId)
        playersReadyAfterBetting.remove(playerId)
        activePlayerIds.removeAll { $0 == playerId }
        print("Player \(playerId) removed.")
        // If the removed player was the current player, advance the turn
        if case .playerTurn(let currentId) = gameState, currentId == playerId {
            advanceToNextPlayer()
        } else if gameState == .betting{
            checkIfAllPlayersHaveBet()
        }
        if activePlayerIds.isEmpty {
            gameState = .waitingForPlayers
        }
    }
    /// Starts a new round of Blackjack.
    func startNewRound() {
        guard !activePlayerIds.isEmpty else {
            print("Cannot start round without players.")
            gameState = .waitingForPlayers
            return
        }

        print("Starting new round...")
        allPlayersHaveBet = false
        // 1. Reset hands, bets (keep players, maybe reset bets later), outcomes
        dealerHand.reset()
        playerOutcomes.removeAll()
        playersReadyAfterBetting.removeAll()
        for id in activePlayerIds {
            playerHands[id]?.reset()
            // TODO: Handle betting properly - reset bets here or require new bets
            playerBets[id] = 10 // Placeholder bet
        }

        // 2. Prepare the deck/shoe if needed
        if shoe.count < (numberOfDecks * 52 / 4) { // Reshuffle if shoe is low (e.g., < 25% left)
            print("Reshuffling shoe...")
            shoe = []
            for _ in 0..<numberOfDecks {
                shoe.append(contentsOf: PlayingCard.standardDeck())
            }
            shoe.shuffle()
            deck = shoe
            print("Round started. State: \(gameState). Waiting for bets.")

            // Update published deck for potential UI display
        } else {
             deck = shoe // Ensure published deck reflects current shoe
        }
        // 3. Set state to Betting (or Dealing if betting is handled elsewhere)
        gameState = .betting

        // For now, skipping betting phase and going straight to dealing
        // Deal immediately after shuffling for this example
        // gameState = .betting // TODO: Implement betting phase UI and logic
        print("THIS IS THE RUNERS UP")
        print("Round started. State: \(gameState)")
    }

     func placeBet(playerId: String, amount: Int) {
         guard case .betting = gameState else {
             print("Cannot place bet outside of betting phase.")
             return
         }
         guard playerHands[playerId] != nil else {
             print("PLACEBET: Player \(playerId) not found.")
             return
         }
         guard amount > 0 else {
             print("Bet amount must be positive.")
             return
         }
         // TODO: Check if player has enough money (requires integrating UserModel)
         playerBets[playerId] = amount
         print("Player \(playerId) bet \(amount).")
         checkIfAllPlayersHaveBet()


         // TODO: Check if all active players have placed bets to proceed
         // let allBetsPlaced = activePlayerIds.allSatisfy { playerBets[$0] ?? 0 > 0 }
         // if allBetsPlaced {
         //     gameState = .dealing
         //     dealInitialHands()
         // }
     }
    
    private func checkIfAllPlayersHaveBet() {
            // This check assumes that a bet > 0 means the player has placed their bet.
            // If a player can bet 0, this logic needs adjustment.
            let betsPlacedByActivePlayers = activePlayerIds.allSatisfy { playerBets[$0] ?? 0 > 0 }

            if betsPlacedByActivePlayers && !activePlayerIds.isEmpty {
                allPlayersHaveBet = true
                print("All active players have placed their bets.")
                gameState = .dealing
                dealInitialHands()
            } else {
                allPlayersHaveBet = false
                print("Waiting for more bets. Current bets: \(playerBets)")
            }
        }
    
    func playerReadyAfterBetting(playerId: String) {
            guard case .betting = gameState else {
                print("Cannot ready up outside of betting phase.")
                return
            }
            guard playerBets[playerId] ?? 0 > 0 else {
                print("Player \(playerId) must place a bet before readying up.")
                // Optionally, you could allow readying up without a bet if your game rules permit (e.g. playing a round with 0 bet)
                // For now, we assume a bet is required.
                return
            }

            playersReadyAfterBetting.insert(playerId)
            print("Player \(playerId) is ready.")
            checkIfAllBettingPlayersAreReady()
        }
    
    private func checkIfAllBettingPlayersAreReady() {
           // Get a list of players who are actually participating (have placed a bet > 0)
           let participatingPlayerIds = activePlayerIds.filter { playerBets[$0] ?? 0 > 0 }

           // If there are no participating players yet, do nothing.
           if participatingPlayerIds.isEmpty && !activePlayerIds.isEmpty {
               print("No players have placed bets yet.")
               return
           }
           
           // If there are no active players at all (e.g., everyone left), perhaps reset.
           if activePlayerIds.isEmpty && gameState == .betting {
               print("All players left during betting. Resetting to waiting.")
               gameState = .waitingForPlayers
               return
           }

           // Check if all *participating* players are in the ready set.
           let allParticipantsReady = participatingPlayerIds.allSatisfy { playersReadyAfterBetting.contains($0) }

           if allParticipantsReady && !participatingPlayerIds.isEmpty {
               print("All participating players have placed bets and are ready. Proceeding to deal.")
               gameState = .dealing
               dealInitialHands()
           } else {
               print("Waiting for more players to place bets and/or ready up. Ready players: \(playersReadyAfterBetting.count)/\(participatingPlayerIds.count) of those who bet.")
           }
       }


    /// Deals the initial two cards to each player and the dealer.
    private func dealInitialHands() {
        guard case .dealing = gameState else { return }
        print("Dealing initial hands...")

        // Deal two cards to each player
        for _ in 0..<2 {
            for id in activePlayerIds {
                if let card = dealCard() {
                    playerHands[id]?.addCard(card)
                }
            }
            // Deal one card to the dealer
            if let card = dealCard() {
                dealerHand.addCard(card)
            }
        }

        // Set card visibility (players' cards face up, dealer's second card face down)
        for id in activePlayerIds {
             playerHands[id]?.cards.indices.forEach { playerHands[id]?.cards[$0].isFaceUp = true }
        }
        if dealerHand.cards.count > 1 {
            dealerHand.cards[0].isFaceUp = true // First dealer card face up
            dealerHand.cards[1].isFaceUp = false // Second dealer card face down
        } else if dealerHand.cards.count == 1 {
             dealerHand.cards[0].isFaceUp = true
        }


        print("Dealer Hand: \(dealerHand.description)")
        for id in activePlayerIds {
            print("Player \(id) Hand: \(playerHands[id]?.description ?? "N/A")")
        }

        // Check for dealer Blackjack
        if dealerHand.isBlackjack {
            print("Dealer has Blackjack!")
            // Reveal dealer's second card
             if dealerHand.cards.count > 1 { dealerHand.cards[1].isFaceUp = true }
            determineOutcome() // End round immediately if dealer has Blackjack
        } else {
            // Check for player Blackjacks
            var anyPlayerBlackjack = false
            for id in activePlayerIds {
                if playerHands[id]?.isBlackjack ?? false {
                    print("Player \(id) has Blackjack!")
                    playerOutcomes[id] = .playerBlackjack // Mark immediate win (usually pays 3:2)
                    anyPlayerBlackjack = true
                    // This player's turn is skipped
                }
            }
            currentPlayerIndex = activePlayerIds.firstIndex(where: { !(playerHands[$0]?.isBlackjack ?? false) }) ?? -1

            if currentPlayerIndex != -1 {
                 let firstPlayerId = activePlayerIds[currentPlayerIndex]
                 gameState = .playerTurn(playerId: firstPlayerId)
                 print("Moving to Player \(firstPlayerId)'s turn.")
            } else {
                 // All players had blackjack or no players left
                 print("No players left to play or only Blackjacks. Determining outcome.")
                 // Reveal dealer's second card
                 if dealerHand.cards.count > 1 { dealerHand.cards[1].isFaceUp = true }
                 determineOutcome() // Determine outcome (pushes for player blackjacks if dealer doesn't have one)
            }
        }
    }

    /// Handles a player's action (Hit or Stand).
    /// - Parameters:
    ///   - playerId: The ID of the player taking the action.
    ///   - action: The action to perform (.hit or .stand).
    func playerAction(playerId: String, action: PlayerAction) {
        guard case .playerTurn(let currentId) = gameState, currentId == playerId else {
            print("Not Player \(playerId)'s turn.")
            return
        }
        // Use a temporary variable for the hand to modify it
        guard var hand = playerHands[playerId] else {
            print("Player \(playerId) hand not found.")
            return
        }

        switch action {
        case .hit:
            print("Player \(playerId) hits.")
            if let card = dealCard() {
                var dealtCard = card
                dealtCard.isFaceUp = true // Make sure dealt card is face up
                hand.addCard(dealtCard) // Add to the temporary hand copy

                // --- IMPORTANT: Update the published property ---
                playerHands[playerId] = hand
                // ---

                print("Player \(playerId) Hand: \(hand.description)") // Log the updated hand

                // --- MODIFIED: Check for 21 or Bust ---
                if hand.score == 21 {
                    print("Player \(playerId) has 21!")
                    // Turn automatically ends when player hits 21
                    advanceToNextPlayer()
                } else if hand.isBusted {
                    print("Player \(playerId) busted!")
                    // Update outcomes directly on the published property
                    playerOutcomes[playerId] = .playerBust
                    advanceToNextPlayer() // Check next player or dealer
                } else {
                    // Player score is < 21, can hit again
                    print("Player \(playerId) can act again.")
                    // No state change needed here, just wait for next action or timeout
                }
                // --- END MODIFICATION ---
            } else {
                 print("Error: Deck is empty during player hit.")
                 // Handle error state appropriately (e.g., end round?)
                 // For now, just advance turn as player cannot hit
                 advanceToNextPlayer()
            }

        case .stand:
            print("Player \(playerId) stands with score \(hand.score).")
            // No change to hand or outcome needed here, just advance turn
            advanceToNextPlayer()
        }
    }

    /// Advances the game state to the next player's turn or to the dealer's turn.
    private func advanceToNextPlayer() {
           currentPlayerIndex += 1
           // Find the next player who hasn't busted or got Blackjack
            while currentPlayerIndex < activePlayerIds.count {
                let nextPlayerId = activePlayerIds[currentPlayerIndex]
                // Check if player has a decided outcome already
                if playerOutcomes[nextPlayerId] == nil {
                    // This player hasn't busted or got Blackjack, it's their turn.
                    gameState = .playerTurn(playerId: nextPlayerId)
                    print("Moving to Player \(nextPlayerId)'s turn.")
                    return // Exit function, wait for player action
                }
                // Otherwise, player is already done (Bust/BJ), increment and check next
                currentPlayerIndex += 1
            }


           // --- MODIFIED LOGIC ---
           // If loop completes, no more players left to act. Check if dealer needs to play.
           print("All players finished acting.")

           // Check if there are any players who stood (outcome is still nil)
           let playersWhoStood = activePlayerIds.filter { id in
               playerOutcomes[id] == nil // Outcome is nil only if player stood (and didn't get BJ initially)
           }

           if playersWhoStood.isEmpty {
               // All players either busted or got Blackjack initially. Dealer doesn't need to play.
               print("All players busted or had Blackjack. Determining outcome immediately.")
               // Reveal dealer's hole card if it hasn't been revealed (e.g., if dealer had potential Blackjack)
               // Ensure we modify the published property
               if dealerHand.cards.count > 1 && !dealerHand.cards[1].isFaceUp {
                    dealerHand.cards[1].isFaceUp = true
                    print("Dealer reveals second card (for outcome determination). Hand: \(dealerHand.description)")
               }
               determineOutcome() // Go straight to outcome determination
           } else {
               // At least one player stood. Dealer must play.
               print("At least one player stood. Moving to Dealer's turn.")
               gameState = .dealerTurn
               dealerPlays() // Start dealer's turn
           }
           // --- END OF MODIFIED LOGIC ---
       }

    /// Executes the dealer's turn based on standard Blackjack rules.
    private func dealerPlays() {
        guard case .dealerTurn = gameState else { return }

        // Reveal dealer's face-down card
        if dealerHand.cards.count > 1 && !dealerHand.cards[1].isFaceUp {
             dealerHand.cards[1].isFaceUp = true
             print("Dealer reveals second card. Hand: \(dealerHand.description)")
             // Need to re-publish state if changes aren't automatic
             // For @Published, this should trigger automatically if Hand is modified correctly
        }


        // Dealer hits until score is 17 or more
        while dealerHand.score < 17 {
            print("Dealer hits.")
            if let card = dealCard() {
                 var dealtCard = card
                 dealtCard.isFaceUp = true
                 dealerHand.addCard(dealtCard)
                 print("Dealer Hand: \(dealerHand.description)")
            } else {
                 print("Error: Deck is empty during dealer turn.")
                 break // Exit loop if deck is empty
            }
        }

        if dealerHand.isBusted {
            print("Dealer busted!")
        } else {
            print("Dealer stands with score \(dealerHand.score).")
        }

        // After dealer plays, determine the outcome for all players
        determineOutcome()
    }

    /// Compares player hands to the dealer's hand and determines the outcome.
    private func determineOutcome() {
        print("Determining round outcome...")
        let dealerScore = dealerHand.score
        let dealerBusted = dealerHand.isBusted
        let dealerHasBlackjack = dealerHand.isBlackjack // Check initial deal blackjack

        for id in activePlayerIds {
            // Skip if outcome already decided (Bust, Player Blackjack)
            if playerOutcomes[id] != nil { continue }

            guard let playerHand = playerHands[id] else { continue }
            let playerScore = playerHand.score

            if dealerBusted {
                print("Player \(id) wins (Dealer Busted). Score: \(playerScore)")
                playerOutcomes[id] = .dealerBust // Player wins because dealer busted
            } else if dealerHasBlackjack {
                 // If player also had blackjack, it's a push, otherwise player loses.
                 // Player Blackjack outcome was set earlier if applicable.
                 if playerHand.isBlackjack {
                      print("Player \(id) pushes (Both Blackjack).")
                      playerOutcomes[id] = .push
                 } else {
                      print("Player \(id) loses (Dealer Blackjack). Score: \(playerScore)")
                      playerOutcomes[id] = .dealerBlackjack // Player loses to dealer blackjack
                 }
            } else if playerScore > dealerScore {
                print("Player \(id) wins. Score: \(playerScore) vs Dealer: \(dealerScore)")
                playerOutcomes[id] = .playerWin
            } else if playerScore == dealerScore {
                print("Player \(id) pushes. Score: \(playerScore) vs Dealer: \(dealerScore)")
                playerOutcomes[id] = .push
            } else { // playerScore < dealerScore
                print("Player \(id) loses. Score: \(playerScore) vs Dealer: \(dealerScore)")
                playerOutcomes[id] = .dealerWin
            }
        }

        gameState = .roundOver
        print("Round over. Final Outcomes: \(playerOutcomes)")
        // TODO: Handle payout logic based on outcomes and bets
    }


    // --- Utility Methods ---

    /// Deals a single card from the shoe.
    /// - Returns: The card dealt, or nil if the shoe is empty.
    private func dealCard() -> PlayingCard? {
        guard !shoe.isEmpty else { return nil }
        let card = shoe.removeFirst()
        deck = shoe // Update published deck
        return card
    }
    
    // --- NEW: Public function to reset state internally ---
    public func resetToWaitingState() {
        print("BlackjackLogicController: Resetting state to waitingForPlayers.")
        // Reset hands, outcomes etc. if needed when going back to waiting
        dealerHand.reset()
        playerOutcomes.removeAll()
        playersReadyAfterBetting.removeAll() // Clear ready set
        activePlayerIds.forEach { id in
            playerHands[id]?.reset()
            playerBets[id] = 0 // Reset bets too
        }
        // Reset shoe? Or keep it for next round? Let's keep it for now.
        // shoe.removeAll()
        // deck = shoe

        // Set the state
        self.gameState = .waitingForPlayers
    }
    
}

