//
//  GameSession.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 11/2/25.
//

import SwiftUI

@MainActor
final class GameSession: ObservableObject {

    // MARK: - Configuration chosen by the user
    @Published var settings: GameSettings = .default

    // MARK: - High-level session state
    enum Phase: Equatable {
        case idle               // No game is running
        case preparing          // Allocating resources, loading assets
        case running            // Game is active
        case paused             // Temporarily paused
        case finished           // Game ended (win/lose/exit)
        case error(String)      // Failure with message
    }
    @Published var phase: Phase = .idle

    // MARK: - Current game identity
    // Keep this simple and general so other games can reuse the same session.
    // You can evolve this to a more structured type later if needed.
    @Published var currentGameType: String? = nil

    // MARK: - Lifecycle helpers
    func beginGame(with settings: GameSettings) {
        // Central entry point for starting any game.
        self.settings = settings
        self.currentGameType = settings.gameType
        self.phase = .preparing
    }

    func markRunning() {
        phase = .running
    }

    func pause() {
        guard phase == .running else { return }
        phase = .paused
    }

    func resume() {
        guard phase == .paused else { return }
        phase = .running
    }

    func endGame() {
        phase = .finished
        // Optional: clear currentGameType if you want a clean slate
        // currentGameType = nil
    }

    func fail(with message: String) {
        phase = .error(message)
    }

    // MARK: - Reset for a brand-new session
    func reset() {
        settings = .default
        currentGameType = nil
        phase = .idle
    }
}
