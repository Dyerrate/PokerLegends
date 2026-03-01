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
        logGameEvent(event)
        self.playerMoney! += amount
    }
    
    func takePlayerLosses(amount: Double) {
        let event = GameEvent(type: .loss, amount: amount)
        logGameEvent(event)
        self.playerMoney! -= amount
    }
    
    
    private func logGameEvent(_ event: GameEvent) {
        //trigger the log to push the event to cloud kit que sync
    }
}
