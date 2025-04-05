//
//  GameObserver.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 10/6/24.
//

import RealityKit
import TabletopKit
import SwiftUI // For @MainActor if needed

@MainActor // Ensure updates happen on main thread
class GameObserver: TabletopGame.Observer {
    // Keep reference to the game to access localPlayer if needed inside callbacks
    unowned let tabletop: TabletopGame
    // Keep renderer reference if used for other observer tasks
    unowned let renderer: GameRenderer
    var gameToRender: String

    // --- State maintained SOLELY by callbacks ---
    // Player.ID -> Seat they occupy
    private(set) var playerSeats: [Player.ID: TableSeatIdentifier] = [:]
    // TableSeatIdentifier -> Player.ID occupying it
    private(set) var seatOccupants: [TableSeatIdentifier: Player.ID] = [:]

    // Removed latestSnapshot cache

    init(tabletop: TabletopGame, renderer: GameRenderer, gameToRender: String) {
        self.tabletop = tabletop
        self.renderer = renderer
        self.gameToRender = gameToRender
        print("GameObserver initialized. Waiting for callbacks to populate state.")
        // Removed initial snapshot handling
    }

    // --- Observer Methods ---

    // Called when the game state updates (snapshot might be useful for other things)
    nonisolated func gameDidUpdate(snapshot: TableSnapshot) {
         Task { @MainActor in
             // We don't update seat mappings here anymore
             // print("GameObserver: gameDidUpdate received.")
             // Use snapshot for other state if needed (e.g., equipment positions)
         }
    }

    // --- THIS IS NOW THE PRIMARY SOURCE FOR SEAT MAPPINGS ---
    nonisolated func playerChangedSeats(_ player: Player, oldSeat: (any TableSeat)?, newSeat: (any TableSeat)?, snapshot: TableSnapshot) {
        // Update mappings on the main thread
        Task { @MainActor in
            print("GameObserver: playerChangedSeats received for Player \(player.id). New seat: \(newSeat?.id.rawValue ?? -1)")

            // Remove old mapping if player moved FROM a seat
            if let oldSeatId = oldSeat?.id {
                // Verify consistency before removing (optional)
                if seatOccupants[oldSeatId] == player.id {
                    seatOccupants.removeValue(forKey: oldSeatId)
                    print("GameObserver: Removed player \(player.id) from old seat \(oldSeatId.rawValue)")
                } else {
                     print("GameObserver: Warning - Mismatch removing player \(player.id) from old seat \(oldSeatId.rawValue)")
                }
            }

            // Remove player from any previous seat mapping (covers cases where oldSeat might be nil unexpectedly)
            playerSeats.removeValue(forKey: player.id)

            // Add new mapping if player moved TO a seat
            if let newSeatId = newSeat?.id {
                seatOccupants[newSeatId] = player.id
                playerSeats[player.id] = newSeatId
                print("GameObserver: Added player \(player.id) to new seat \(newSeatId.rawValue)")
            } else {
                 print("GameObserver: Player \(player.id) is now unseated.")
            }

            // Auto-claim logic (check if still needed/working)
            if player.id == tabletop.localPlayer.id, newSeat == nil {
                 print("GameObserver: Local player unseated, attempting to claim any seat.")
                 Task {
                     // We need 'tabletop' reference here
                     let success = await self.tabletop.claimAnySeat()
                     print("GameObserver: Auto-claim result: \(success)")
                 }
            }
        }
    }

    // --- Implement other required methods, ensure mappings are updated ---

    // Example: Player Removed - clear them from mappings
    nonisolated func playerRemoved(_ player: Player, snapshot: TableSnapshot) {
         Task { @MainActor in
             print("GameObserver: playerRemoved received for Player \(player.id)")
             if let removedSeatId = playerSeats.removeValue(forKey: player.id) {
                 // Also remove from the seat occupant mapping
                 if seatOccupants[removedSeatId] == player.id {
                     seatOccupants.removeValue(forKey: removedSeatId)
                 }
             }
         }
    }

    // --- Accessor Methods ---

    /// Returns the Player ID occupying the specified seat based on internal state.
    /// Note: Returns Player.ID?, not Player? as we don't store Player objects directly.
    func playerId(in seatId: TableSeatIdentifier) -> Player.ID? {
        // Directly access the internally maintained dictionary
        return seatOccupants[seatId]
    }

    /// Returns the seat occupied by the specified player based on internal state.
    func seat(for player: Player) -> TableSeatIdentifier? {
         // Directly access the internally maintained dictionary
         return playerSeats[player.id]
    }

    // --- Implement other required TabletopGame.Observer methods ---
    // Add stubs or implementations for other methods like:
    // nonisolated func equipmentAdded(_ equipment: any Equipment, snapshot: TableSnapshot) { print("Observer: Equip Added") }
    // nonisolated func equipmentRemoved(_ equipmentID: EquipmentIdentifier, snapshot: TableSnapshot) { print("Observer: Equip Removed") }
    // nonisolated func equipmentChanged(_ equipment: any Equipment, snapshot: TableSnapshot) { print("Observer: Equip Changed") }
    // nonisolated func playerAdded(_ player: Player, snapshot: TableSnapshot) { print("Observer: Player Added") }
    // ... etc.
}

// Make sure TableSeatIdentifier is Hashable if used as Dictionary key
extension TableSeatIdentifier: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}


