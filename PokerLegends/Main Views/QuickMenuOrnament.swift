//
//  QuickMenuOrnament.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 1/18/26.
//

import SwiftUI

struct QuickMenuOrnament: View {
    @Environment(\.openWindow) private var openWindow
    @State private var isExpanded = false
    
    var body: some View {
        VStack {
            if isExpanded {
                VStack(spacing: 10) {
                    QuickActionButton(
                        systemImage: "chart.bar.fill",
                        action: { openWindow(id: "game-stats") }
                    )
                    
                    QuickActionButton(
                        systemImage: "person.circle.fill",
                        action: { openWindow(id: "player-profile") }
                    )
                    
                    QuickActionButton(
                        systemImage: "gear.circle.fill",
                        action: { openWindow(id: "game-settings") }
                    )
                }
                .padding(8)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                .transition(.scale.combined(with: .opacity))
            }
            
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                Image(systemName: isExpanded ? "xmark" : "ellipsis")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(.regularMaterial, in: Circle())
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .buttonStyle(.plain)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
    }
}

struct QuickActionButton: View {
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundColor(.primary)
                .frame(width: 36, height: 36)
                .background(.thinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    QuickMenuOrnament()
}