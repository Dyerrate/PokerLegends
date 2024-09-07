//
//  GameCardModel.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 7/26/24.
//
import Foundation
import SwiftUI

struct GameCardModel: Identifiable {
    var id = UUID()
    var title: String
    var image: String
    var buttonText: String
    var playerCountText: String
}

struct GameData {
    static let gameCardData = [GameCardModel(title: "Black Jack", image: "BlackJack", buttonText:"Play", playerCountText: "1-7"), GameCardModel(title: "Texas Hold 'Em", image: "texasHold", buttonText: "Play", playerCountText: "2-10"), GameCardModel(title: "Roulette", image: "RouletteTable", buttonText: "Play", playerCountText: "1-10"), GameCardModel(title: "Craps", image: "crapsTable", buttonText: "Play", playerCountText: " 1-10")]
}
