//
//  GameObserver.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 10/6/24.
//

//
//  GameObserver.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 10/6/24.
//

//
//  GameObserver.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 10/6/24.
//

import RealityKit
import TabletopKit
import SwiftUI
import Combine // <-- Import Combine

@MainActor
class GameObserver: TabletopGame.Observer {
    unowned let tabletop: TabletopGame
    unowned let renderer: GameRenderer
    var gameToRender: String

    // State maintained by callbacks
    private(set) var playerSeats: [Player.ID: TableSeatIdentifier] = [:]
    private(set) var seatOccupants: [TableSeatIdentifier: Player.ID] = [:]

    // --- ADDED: Combine Subject to publish local player seating event ---
    let localPlayerSeatedSubject = PassthroughSubject<Player.ID, Never>()
    // --- End of Addition ---

    init(tabletop: TabletopGame, renderer: GameRenderer, gameToRender: String) {
        self.tabletop = tabletop
        self.renderer = renderer
        self.gameToRender = gameToRender
        print("GameObserver initialized. Waiting for callbacks...")
    }

    // --- Observer Methods ---

    nonisolated func gameDidUpdate(snapshot: TableSnapshot) { /* ... */ }

    nonisolated func playerChangedSeats(_ player: Player, oldSeat: (any TableSeat)?, newSeat: (any TableSeat)?, snapshot: TableSnapshot) {
        let tabletopRef = self.tabletop
        // Capture subject reference for use in Task
        let seatedSubject = self.localPlayerSeatedSubject

        Task { @MainActor in
            let playerDesc = player.id == tabletopRef.localPlayer.id ? "Local Player (\(player.id))" : "Remote Player (\(player.id))"
            let oldSeatDesc = oldSeat?.id.rawValue ?? -1
            let newSeatDesc = newSeat?.id.rawValue ?? -1
            print("--- GameObserver: playerChangedSeats ---")
            print("    Player: \(playerDesc)")
            print("    Old Seat ID: \(oldSeatDesc)")
            print("    New Seat ID: \(newSeatDesc)")

            // --- Update internal state (same logic as before) ---
            if let oldSeatId = oldSeat?.id {
                if seatOccupants[oldSeatId] == player.id {
                    seatOccupants.removeValue(forKey: oldSeatId)
                    // print("GameObserver: Removed player \(player.id) from old seat \(oldSeatId.rawValue)") // Verbose logging removed for clarity
                }
            }
            if let previousSeat = playerSeats.removeValue(forKey: player.id) {
                 if seatOccupants[previousSeat] == player.id && oldSeat?.id != previousSeat {
                      seatOccupants.removeValue(forKey: previousSeat)
                 }
            }
            if let newSeatId = newSeat?.id {
                seatOccupants[newSeatId] = player.id
                playerSeats[player.id] = newSeatId
                print("GameObserver: Updated internal state for player \(player.id) in new seat \(newSeatId.rawValue)")

                // --- ADDED: Publish event if local player is seated ---
                if player.id == tabletopRef.localPlayer.id {
                    print("--- GameObserver: Local player SEATED in seat \(newSeatId.rawValue). Publishing event. ---")
                    seatedSubject.send(player.id) // Send notification
                }
                // --- End of Addition ---

            } else {
                 print("GameObserver: Player \(player.id) is now unseated.")
            }
             print("--- GameObserver: playerChangedSeats End ---")
        }
    }

    // Other observer methods (playerRemoved, playerAdded, etc.) remain the same
     nonisolated func playerRemoved(_ player: Player, snapshot: TableSnapshot) {
         let tabletopRef = self.tabletop
         Task { @MainActor in
             let playerDesc = player.id == tabletopRef.localPlayer.id ? "Local Player" : "Player \(player.id)"
             print("GameObserver: playerRemoved received for \(playerDesc)")
             if let removedSeatId = playerSeats.removeValue(forKey: player.id) {
                 if seatOccupants[removedSeatId] == player.id {
                     seatOccupants.removeValue(forKey: removedSeatId)
                 }
             }
         }
     }
     nonisolated func playerAdded(_ player: Player, snapshot: TableSnapshot) {
         let tabletopRef = self.tabletop
         Task { @MainActor in
              let playerDesc = player.id == tabletopRef.localPlayer.id ? "Local Player" : "Player \(player.id)"
              print("GameObserver: playerAdded received for \(playerDesc)")
         }
     }
     nonisolated func equipmentAdded(_ equipment: any Equipment, snapshot: TableSnapshot) { /* ... */ }
     nonisolated func equipmentRemoved(_ equipmentID: EquipmentIdentifier, snapshot: TableSnapshot) { /* ... */ }
     nonisolated func equipmentChanged(_ equipment: any Equipment, snapshot: TableSnapshot) { /* ... */ }


    // Accessor Methods (remain the same)
    func playerId(in seatId: TableSeatIdentifier) -> Player.ID? { return seatOccupants[seatId] }
    func seat(for player: Player) -> TableSeatIdentifier? { return playerSeats[player.id] }
}

// Hashable conformance for TableSeatIdentifier (remains the same)
extension TableSeatIdentifier: Hashable { /* ... */
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
 }





