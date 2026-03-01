//
//  InGameMenuView.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 1/18/26.
//

import SwiftUI

struct InGameMenuView: View {
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 25) {
                Text("Game Menu")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(spacing: 20) {
                    // Quick Actions
                    MenuButton(
                        title: "Game Statistics",
                        systemImage: "chart.bar.fill",
                        action: {
                            openWindow(id: "game-stats")
                        }
                    )
                    
                    MenuButton(
                        title: "Player Profile",
                        systemImage: "person.circle.fill",
                        action: {
                            openWindow(id: "player-profile")
                        }
                    )
                    
                    MenuButton(
                        title: "Game Settings",
                        systemImage: "gear.circle.fill",
                        action: {
                            openWindow(id: "game-settings")
                        }
                    )
                    
                    Divider()
                    
                    // Game Controls
                    MenuButton(
                        title: "Pause Game",
                        systemImage: "pause.circle.fill",
                        action: {
                            // Pause game logic
                            dismissWindow()
                        }
                    )
                    
                    MenuButton(
                        title: "Save & Exit",
                        systemImage: "square.and.arrow.down.fill",
                        action: {
                            // Save and exit logic
                            dismissWindow()
                        }
                    )
                }
                .padding()
                
                Spacer()
            }
            .padding()
            .frame(minWidth: 300, minHeight: 400)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismissWindow()
                    }
                }
            }
        }
    }
}

struct MenuButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 30)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    InGameMenuView()
}