//
//  GameEvent.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 2/7/26.
//


//For creating a event to log into CloudKit changes for userModel
import Foundation

struct GameEvent: Identifiable, Codable {
    enum EventType: String, Codable {
        case bet, win, loss, payout
    }
    var id: UUID = UUID()
    var type: EventType
    var amount: Double
    //var metadata: [String: String]? // for extensibility
}
