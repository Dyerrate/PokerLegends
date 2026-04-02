//
//  LoginStreakService.swift
//  PokerLegends
//
//  Evaluates login streak progression and milestone rewards.
//  Pure logic — no CloudKit, no UI dependencies.

import Foundation

enum StreakEvaluation {
    /// Player already logged in today — nothing changes.
    case alreadyLoggedInToday
    /// Streak continues. newStreak is the updated count (1–14).
    case streakContinued(newStreak: Int)
    /// Gap of more than 1 day — streak resets to 1.
    case streakBroken
}

struct LoginStreakService {

    static let maxStreak = 14

    /// Reward chip amounts for reaching each milestone day.
    static let milestoneRewards: [Int: Double] = [
        1:  500,
        3:  1_000,
        7:  5_000,
        10: 10_000,
        14: 25_000
    ]

    /// Evaluates the streak given the stored last-login date and current streak count.
    /// - Parameters:
    ///   - lastLoginDate: The calendar day of the player's previous login (nil = first ever login).
    ///   - currentStreak: The stored streak count.
    /// - Returns: A `StreakEvaluation` describing what happened.
    static func evaluate(lastLoginDate: Date?, currentStreak: Int) -> StreakEvaluation {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let last = lastLoginDate else {
            // First login ever — start streak at 1.
            return .streakContinued(newStreak: 1)
        }

        let lastDay = calendar.startOfDay(for: last)
        let daysBetween = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

        switch daysBetween {
        case 0:
            return .alreadyLoggedInToday
        case 1:
            let next = min(currentStreak + 1, maxStreak)
            return .streakContinued(newStreak: next)
        default:
            // Missed at least one day — streak broken, restart at 1.
            return .streakBroken
        }
    }

    /// Returns the chip reward for reaching a given streak day, or nil if no milestone.
    static func reward(forDay day: Int) -> Double? {
        return milestoneRewards[day]
    }
}
