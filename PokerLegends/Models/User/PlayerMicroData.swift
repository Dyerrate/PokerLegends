//
//  PlayerMicroData.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 12/17/25.
//

import CloudKit
import Foundation

// --- ALL DATA RELATED TO PLAYERS ---
struct PlayerMicroData: Identifiable {
    // Variables
    let id: UUID
    let parentRecordId: CKRecord.ID
    let totalWinnings: Double
    let totalLosses: Double
    let largestPotWin: Double
    let winStreak: Int
    let totalGamesPlayed: Int
    let player: CKRecord.ID?

    // MARK: - Designated initializers
    init(
        id: UUID = UUID(),
        parentRecordId: CKRecord.ID,
        totalWinnings: Double = 0,
        totalLosses: Double = 0,
        largestPotWin: Double = 0,
        winStreak: Int = 0,
        totalGamesPlayed: Int = 0,
        player: CKRecord.ID? = nil
    ) {
        self.id = id
        self.parentRecordId = parentRecordId
        self.totalWinnings = totalWinnings
        self.totalLosses = totalLosses
        self.largestPotWin = largestPotWin
        self.winStreak = winStreak
        self.totalGamesPlayed = totalGamesPlayed
        self.player = player
    }

    /// Convenience initializer when you only have the parent record and optional player reference.
    init(parentRecordId: CKRecord.ID) {
        self.init(
            id: UUID(),
            parentRecordId: parentRecordId,
            totalWinnings: 0,
            totalLosses: 0,
            largestPotWin: 0,
            winStreak: 0,
            totalGamesPlayed: 0,
        )
    }
}

extension PlayerMicroData {
    // MARK: - Test Data
    /// A single deterministic test instance for previews and unit tests.
    static var test: PlayerMicroData {
        let parent = CKRecord.ID(recordName: "TEST_PARENT_RECORD")
        let playerRef = CKRecord.ID(recordName: "TEST_PLAYER_RECORD")
        return PlayerMicroData(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            parentRecordId: parent,
            totalWinnings: 1250.50,
            totalLosses: 830.10,
            largestPotWin: 420.00,
            winStreak: 4,
            totalGamesPlayed: 37,
            player: playerRef
        )
    }
}

