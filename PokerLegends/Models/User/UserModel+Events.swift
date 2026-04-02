//
//  UserModel+Events.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 2/7/26.
//
import Foundation

extension UserModel {
    func userAddBet(amount: Double) {
        self.playerMoney! -= amount
    }
    
    func addPlayerWinning(amount: Double) {
        let event = GameEvent(type: .win, amount: amount)
        self.playerMoney! += amount
        logGameEvent(event)
    }
    
    func takePlayerLosses(amount: Double) {
        let event = GameEvent(type: .loss, amount: amount)
        self.playerMoney! -= amount
        logGameEvent(event)
    }
    
    private func logGameEvent(_ event: GameEvent) {
        // Sync the updated balance to CloudKit in the background after each round outcome.
        userManager?.updatePlayerBalance(for: self)
    }
}
