//
//  GameSetup.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 9/28/24.
//

import TabletopKit
import RealityKit
import SwiftUI
import Spatial

// Assuming GameMetrics exists as defined before
enum GameMetrics {
    static let tableEdge: Float = 1.2 // Example: Slightly larger table maybe?
    static let tableThickness: Float = 0.05
    // Add other metrics as needed
}

@MainActor
class GameSetup {
    let root: Entity // Root entity for all game elements in this setup
    var setup: TableSetup // The TabletopKit setup object
    let seats: [PlayerSeat] // Player seats (now defined in GameEquipment)

    // Keep track of dynamically created equipment for Blackjack
    var playerHandAreas: [PlayerHandArea] = []
    var bettingSpots: [BettingSpot] = []
    // Cards will be managed dynamically by BlackJackGame, not stored here directly

    // Use the IdentifierGenerator as before
    struct IdentifierGenerator {
        private var count = 1000 // Start IDs higher to avoid conflict with static ones

        mutating func newId() -> Int {
            count += 1
            return count
        }
    }
    var idGenerator = IdentifierGenerator()

    // --- Initialization with Conditional Logic ---
    init(root: Entity, currentGame: String) {
        self.root = root
        self.setup = TableSetup(tabletop: Table()) // Create the basic table

        // --- 1. Setup Seats (Common to most card games) ---
        var tempSeats: [PlayerSeat] = []
        // Iterate with index to get both seat index and pose
        for (index, pose) in PlayerSeat.seatPoses.enumerated() {
            // Use index for TableSeatIdentifier
            let seatId = TableSeatIdentifier(index)
            let seat = PlayerSeat(id: seatId, pose: pose)
            tempSeats.append(seat)
            setup.add(seat: seat) // Add seat to the TabletopKit setup
        }
        self.seats = tempSeats // Store the created seats

        // --- 2. Setup Game-Specific Equipment ---
        if currentGame == "blackJack" {
            setupBlackjackEquipment()
        } else {
            // TODO: Add setup for other games (Poker, Roulette, etc.)
            setupGenericOrOtherGameEquipment(gameName: currentGame)
        }

        // --- 3. Setup Common Equipment (Optional) ---
        // If there's equipment common to all games, add it here.
        // Example: Maybe a general discard pile area?
    }

    // --- Blackjack Specific Setup Function ---
    private func setupBlackjackEquipment() {
        print("Setting up Blackjack equipment...")

        // a) Add Dealer Hand Area
        let dealerArea = DealerHandArea()
        setup.add(equipment: dealerArea)

        // b) Add Card Shoe
        let shoe = CardShoe()
        setup.add(equipment: shoe)
        // Note: We don't create the actual PlayingCardEquipment here.
        // BlackJackGame will create them dynamically based on BlackjackLogicController
        // and set their initial parent to the shoe's ID (EquipmentIdentifier(101)).

        // c) Add Player Hand Areas and Betting Spots for each seat
        // Iterate using the indices of the seats array
        for index in seats.indices {
            // Create Player Hand Area using the index
            let handAreaId = EquipmentIdentifier(idGenerator.newId())
            let handArea = PlayerHandArea(id: handAreaId, seatIndex: index) // Pass index
            setup.add(equipment: handArea)
            playerHandAreas.append(handArea) // Keep track if needed

            // Create Betting Spot using the index
            let bettingSpotId = EquipmentIdentifier(idGenerator.newId())
            let bettingSpot = BettingSpot(id: bettingSpotId, seatIndex: index) // Pass index
            setup.add(equipment: bettingSpot)
            bettingSpots.append(bettingSpot) // Keep track if needed
        }
        print("Blackjack setup complete: Dealer Area, Shoe, \(playerHandAreas.count) Hand Areas, \(bettingSpots.count) Betting Spots added.")
    }

    // --- Placeholder for Other Game Setups ---
    private func setupGenericOrOtherGameEquipment(gameName: String) {
        print("Setting up equipment for game: \(gameName)")
        // Example: Add the generic 'Board' if used for other games
        // let board = Board(id: EquipmentIdentifier(self.idGenerator.newId()))
        // setup.add(equipment: board)

        // Add setup specific to Poker, Roulette, etc.
    }

    // --- Removed Old/Generic Setup Elements ---
    // Remove the direct creation of CardStockGroup, counter, cards array etc.
    // if they are handled within the specific game setups now.
    /*
    var cardStockGroup: CardStockGroup // Removed or adapted
    let counter: ScoreCounter // Removed or adapted
    var cards: [Card] = [] // Removed - cards managed dynamically
    */
}
