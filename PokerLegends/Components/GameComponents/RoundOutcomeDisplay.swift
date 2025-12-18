//
//  RoundOutcomeDisplay.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 7/27/25.
//

import SwiftUI
import RealityKit

struct RoundOutcomeDisplay: View {
    let outcome: GameOutcome
    let winAmount: Double?
    let playerScore: Int?
    let dealerScore: Int?
    
    
    var body: some View {
        VStack(spacing: 20) {
             Text(outcomeText)
                .font(.extraLargeTitle)
                .fontWeight(.bold)
                .foregroundStyle(outcomeColor)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 2, y: 2)
            
            if let playerScore = playerScore, let dealerScore = dealerScore {
                HStack(spacing: 30) {
                    VStack {
                        Text("You")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("\(playerScore)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                    }
                    
                    Text("vs")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    
                    VStack {
                        Text("Dealer")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("\(dealerScore)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.red)
                    }
                }
            }
            
            if let winAmount = winAmount, winAmount > 0 {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundStyle(.yellow)
                    Text("+\(Int(winAmount))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.yellow)
                }
            }
        }
        .padding(30)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay (
            RoundedRectangle(cornerRadius: 20)
                .stroke(outcomeColor, lineWidth: 3)
        )
    }
    
    
    private var outcomeText: String {
            switch outcome {
            case .playerWin:
                return "🎉 You Win! 🎉"
            case .playerBlackjack:
                return "🔥 BLACKJACK! 🔥"
            case .dealerBust:
                return "💥 Dealer Busts! 💥"
            case .dealerWin:
                return "😔 Dealer Wins"
            case .dealerBlackjack:
                return "🃏 Dealer Blackjack"
            case .playerBust:
                return "💔 You Bust"
            case .push:
                return "🤝 Push (Tie)"
            }
        }
    
    private var outcomeColor: Color {
            switch outcome {
            case .playerWin, .playerBlackjack, .dealerBust:
                return .green
            case .dealerWin, .dealerBlackjack, .playerBust:
                return .red
            case .push:
                return .orange
            }
        }
}
