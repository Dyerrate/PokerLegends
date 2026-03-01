//
//  PlayingCard.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 4/1/25.
//


import Foundation

// Represents the suit of a standard playing card.
enum Suit: String, CaseIterable, Codable {
    case hearts = "♥️"
    case diamonds = "♦️"
    case clubs = "♣️"
    case spades = "♠️"
}

// Represents the rank of a standard playing card.
enum Rank: Int, CaseIterable, Codable, Comparable {
    case two = 2, three, four, five, six, seven, eight, nine, ten
    case jack, queen, king, ace

    // Provides the display name for the rank.
    var stringValue: String {
        switch self {
        case .ace: return "A"
        case .king: return "K"
        case .queen: return "Q"
        case .jack: return "J"
        default: return String(self.rawValue)
        }
    }

    // Provides the Blackjack value(s) for the rank. Ace can be 1 or 11.
    var blackjackValue: [Int] {
        switch self {
        case .ace: return [1, 11] // Ace can be 1 or 11
        case .king, .queen, .jack: return [10] // Face cards are worth 10
        default: return [self.rawValue] // Number cards are worth their face value
        }
    }

    // Conformance to Comparable for sorting or comparison if needed.
    static func < (lhs: Rank, rhs: Rank) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// Represents a standard playing card with a suit and rank.
struct PlayingCard: Identifiable, Codable, Hashable {
    var id = UUID() // Unique identifier for each card instance
    let rank: Rank
    let suit: Suit
    var isFaceUp: Bool = true // Determines if the card's face is visible

    // Provides a simple description of the card (e.g., "A♠️").
    var description: String {
        return "\(rank.stringValue)\(suit.rawValue)"
    }

    // Conformance to Hashable.
    func hash(into hasher: inout Hasher) {
        hasher.combine(rank)
        hasher.combine(suit)
    }

    // Conformance to Equatable (implied by Hashable).
    static func == (lhs: PlayingCard, rhs: PlayingCard) -> Bool {
        return lhs.rank == rhs.rank && lhs.suit == rhs.suit
    }
}

// Extension to create a standard 52-card deck.
extension PlayingCard {
    static func standardDeck() -> [PlayingCard] {
        var deck: [PlayingCard] = []
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                deck.append(PlayingCard(rank: rank, suit: suit))
            }
        }
        return deck
    }
}
