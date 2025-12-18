//
//  GameSettings.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 10/25/25.
//
//

import Foundation
import SwiftUI

@MainActor
struct GameSettings: Codable {
    var theme: GameTheme
    var location: GameLocation
    var numberOfDecks: Int
    var gameType: String
    
    enum GameTheme: String, CaseIterable, Codable {
        case classic = "Classic Casino"
        case neon = "Neon Nights"
        case luxury = "Luxury Gold"
        case minimal = "Minimal Modern"
        
        var icon: String {
            switch self {
            case .classic: return "suit.spade.fill"
            case .neon: return "bolt.fill"
            case .luxury: return "crown.fill"
            case .minimal: return "circle.fill"
            }
        }
        
        var description: String {
            switch self {
            case .classic: return "Traditional red felt & wood"
            case .neon: return "Cyberpunk style with glow"
            case .luxury: return "Gold accents & premium feel"
            case .minimal: return "Clean & simple design"
            }
        }
    }
    
    enum GameLocation: String, CaseIterable, Codable {
        case vegas = "Las Vegas"
        case monaco = "Monte Carlo"
        case macau = "Macau"
        case home = "Home Game"
        
        var icon: String {
            switch self {
            case .vegas: return "building.2.fill"
            case .monaco: return "sparkles"
            case .macau: return "star.fill"
            case .home: return "house.fill"
            }
        }
        
        var description: String {
            switch self {
            case .vegas: return "Bright lights & high stakes"
            case .monaco: return "Elegant European style"
            case .macau: return "Asian luxury atmosphere"
            case .home: return "Casual friendly environment"
            }
        }
    }
    
    // Default settings
    static var `default`: GameSettings {
        GameSettings(
            theme: .classic,
            location: .home,
            numberOfDecks: 4,
            gameType: "blackJack"
        )
    }
}
