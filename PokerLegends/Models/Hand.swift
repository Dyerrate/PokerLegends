//
//  Hand.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 4/1/25.
//

import Foundation

// Represents a hand of playing cards for a player or dealer.
struct Hand: Identifiable, Codable {
    let id = UUID() // Unique identifier for the hand instance
    var cards: [PlayingCard] = [] // The cards currently in the hand

    // Calculates the best possible Blackjack score for the hand.
    // Aces are treated as 11 unless the total exceeds 21, then they become 1.
    var score: Int {
        var total = 0
        var aceCount = 0

        // Sum card values, counting Aces initially as 11.
        for card in cards {
            if card.rank == .ace {
                aceCount += 1
                total += 11 // Assume Ace is 11 initially
            } else {
                // Use the first value (most ranks only have one value).
                total += card.rank.blackjackValue.first ?? 0
            }
        }

        // Adjust Ace values from 11 to 1 if the total exceeds 21.
        while total > 21 && aceCount > 0 {
            total -= 10 // Change an Ace from 11 to 1
            aceCount -= 1
        }
        return total
    }

    // Checks if the hand's score exceeds 21.
    var isBusted: Bool {
        return score > 21
    }

    // Checks if the hand is a Blackjack (Ace + 10-value card on the first two cards).
    var isBlackjack: Bool {
        return cards.count == 2 && score == 21
    }

    // Adds a card to the hand.
    mutating func addCard(_ card: PlayingCard) {
        cards.append(card)
    }

    // Resets the hand to be empty.
    mutating func reset() {
        cards = []
    }

    // Provides a description of the hand (e.g., "A♠️, K♣️ (21)").
    var description: String {
        let cardStrings = cards.map { $0.isFaceUp ? $0.description : "??" }.joined(separator: ", ")
        return "\(cardStrings) (\(score))"
    }
}
