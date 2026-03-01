//
//  GameStatsView.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 1/18/26.
//

import SwiftUI

struct GameStatsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Game Statistics")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 15) {
                    StatRow(label: "Games Played", value: "23")
                    StatRow(label: "Games Won", value: "14")
                    StatRow(label: "Win Rate", value: "60.9%")
                    StatRow(label: "Highest Bet", value: "$500")
                    StatRow(label: "Total Winnings", value: "$2,340")
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    GameStatsView()
}