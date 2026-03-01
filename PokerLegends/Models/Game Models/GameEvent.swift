//
//  GameEvent.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 2/7/26.
//

struct GameEvent: Identifiable, Codable {
    enum EventType: String, Codable {
        case bet, win, loss, payout
    }
    var id: UUID = UUID()
    var type: EventType
    var amount: Double
    var timestamp: Date
    var metadata: [String: String]? // for extensibility
}
