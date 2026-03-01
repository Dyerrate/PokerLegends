//
//  GameStatsModel.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 8/10/24.
//

import Foundation

class GameStats: Identifiable, ObservableObject {
    
    var id = UUID()
    var totalWinnings: Double?
    var totalLosses: Double?
    var largestWinningHand: Double?
    var mostPlayedGamemode: String?
    
}
