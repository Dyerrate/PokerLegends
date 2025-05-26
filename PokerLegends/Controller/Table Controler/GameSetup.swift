//
//  GameSetup.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 9/28/24.
//

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
    static let tableEdge: Float = 1.2
    static let tableThickness: Float = 0.05
    // Add other metrics as needed
}

@MainActor
class GameSetup {
    let root: Entity // Root entity for all game elements in this setup
    var setup: TableSetup // The TabletopKit setup object
    let seats: [PlayerSeat] // Player seats (defined in GameEquipment)

    // Keep track of dynamically created equipment for Blackjack if needed elsewhere
    var playerHandAreas: [PlayerHandArea] = []
    var bettingSpots: [BettingSpot] = []

    // IdentifierGenerator (keep as is)
    struct IdentifierGenerator { /* ... */
        private var count = 1000
        mutating func newId() -> Int { count += 1; return count }
     }
    var idGenerator = IdentifierGenerator()

    // --- Initialization with Conditional Logic ---
    init(root: Entity, currentGame: String) {
        print("--- GameSetup: Initializing for game '\(currentGame)' ---")
        self.root = root
        self.setup = TableSetup(tabletop: Table()) // Create the basic table

        // --- 1. Setup Seats (Common to most card games) ---
        print("--- GameSetup: Setting up player seats ---")
        var tempSeats: [PlayerSeat] = []
        // Iterate with index to get both seat index and pose
        for (index, pose) in PlayerSeat.seatPoses.enumerated() {
            // Use index for TableSeatIdentifier
            let seatId = TableSeatIdentifier(index)
            let seat = PlayerSeat(id: seatId, pose: pose)
            tempSeats.append(seat)
            setup.add(seat: seat) // Add seat to the TabletopKit setup
            // --- ADDED Logging ---
            print("--- GameSetup: Added seat with ID \(seatId.rawValue) to TableSetup ---")
        }
        self.seats = tempSeats // Store the created seats
        print("--- GameSetup: Finished adding \(self.seats.count) seats ---")

        // --- 2. Setup Game-Specific Equipment ---
        if currentGame == "blackJack" {
            setupBlackjackEquipment()
        } else {
            setupGenericOrOtherGameEquipment(gameName: currentGame)
        }
        print("--- GameSetup: Initialization complete ---")
    }

    // --- Blackjack Specific Setup Function ---
    private func setupBlackjackEquipment() {
        print("--- GameSetup: Setting up Blackjack equipment ---")

        // a) Add Dealer Hand Area
        let dealerArea = DealerHandArea()
        setup.add(equipment: dealerArea)
        print("--- GameSetup: Added DealerHandArea (ID: \(dealerArea.id.rawValue)) ---")


        // b) Add Card Shoe
        let shoe = CardShoe()
        setup.add(equipment: shoe)
        print("--- GameSetup: Added CardShoe (ID: \(shoe.id.rawValue)) ---")


        // c) Add Player Hand Areas and Betting Spots for each seat
        for index in seats.indices {
            // Create Player Hand Area using the index
            let handAreaId = EquipmentIdentifier(idGenerator.newId())
            let handArea = PlayerHandArea(id: handAreaId, seatIndex: index)
            setup.add(equipment: handArea)
            playerHandAreas.append(handArea)
            print("--- GameSetup: Added PlayerHandArea (ID: \(handAreaId.rawValue)) for seat \(index) ---")


            // Create Betting Spot using the index
            let bettingSpotId = EquipmentIdentifier(idGenerator.newId())
            let bettingSpot = BettingSpot(id: bettingSpotId, seatIndex: index)
            setup.add(equipment: bettingSpot)
            bettingSpots.append(bettingSpot)
            print("--- GameSetup: Added BettingSpot (ID: \(bettingSpotId.rawValue)) for seat \(index) ---")

        }
        print("--- GameSetup: Blackjack equipment setup complete ---")
    }

    // --- Placeholder for Other Game Setups ---
    private func setupGenericOrOtherGameEquipment(gameName: String) {
        print("--- GameSetup: Setting up equipment for game: \(gameName) (Placeholder) ---")
        // Example: Add the generic 'Board' if used for other games
        // let board = Board(id: EquipmentIdentifier(self.idGenerator.newId()))
        // setup.add(equipment: board)
    }
}
