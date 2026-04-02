//
//  UserManager.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 8/10/24.
//


import Foundation
import AuthenticationServices
import Combine
import UIKit

class UserManager: ObservableObject {
    @Published var session: UserSession = .unauthenticated
    private let signInService = AppleSignInService()
    private let userService = CloudKitUserService()

    func signIn() {
        print("[UserManager] signIn tapped")
        print("[UserManager] setting session to .loading")
        self.session = .loading
        Task { [weak self] in
            guard let self else { return }
            do {
                let credential = try await signInService.startSignIn()
                print("[UserManager] Received credential. user=\(credential.user), email=\(String(describing: credential.email))")
                let appleUserId = credential.user
                let email = credential.email
                let derivedUsername = {
                    // Only non-empty if Apple provided fullName on first authorization
                    let name = PersonNameComponentsFormatter().string(from: credential.fullName ?? PersonNameComponents())
                    return name.isEmpty ? nil : name
                }()
                print("[UserManager] Calling fetchOrCreateUser with appleUserId=\(appleUserId), email=\(String(describing: email)), username=\(String(describing: derivedUsername))")

                // Try fetch or create
                let record = try await userService.fetchOrCreateUser(
                    appleUserId: appleUserId,
                    email: email,
                    username: derivedUsername
                    
                )
                print("[UserManager] Received CKRecord id=\(record.recordID.recordName)")
                guard let model = UserModel(record: record) else { throw NSError(domain: "Mapping", code: -1) }
                print("[UserManager] Mapping to UserModel succeeded. Updating session to .authenticated")
                model.userManager = self
                await MainActor.run { self.session = .authenticated(model) }
                // Evaluate and persist login streak after session is set.
                self.checkAndUpdateLoginStreak(for: model)
            } catch {
                print("[UserManager] signIn failed with error: \(error)")
                await MainActor.run { self.session = .failed(error.localizedDescription) }
            }
        }
    }

    /// Fire-and-forget: persists the new balance to CloudKit in the background.
    /// Safe to call after every round — the Task runs independently of the UI.
    func updatePlayerBalance(for model: UserModel) {
        guard let balance = model.playerMoney else { return }
        let recordId = model.id
        Task {
            do {
                try await userService.updatePlayerBalance(recordId: recordId, newBalance: balance)
                print("[UserManager] Balance synced to CloudKit: \(balance)")
            } catch {
                print("[UserManager] Failed to sync balance: \(error)")
            }
        }
    }

    /// Evaluates the login streak for the given model and persists any changes to CloudKit.
    /// Grants chip rewards for milestone days via the existing balance sync path.
    private func checkAndUpdateLoginStreak(for model: UserModel) {
        let evaluation = LoginStreakService.evaluate(
            lastLoginDate: model.lastLoginDate,
            currentStreak: model.loginStreakCount
        )

        switch evaluation {
        case .alreadyLoggedInToday:
            print("[UserManager] Login streak: already counted today (streak=\(model.loginStreakCount))")
            return

        case .streakContinued(let newStreak):
            print("[UserManager] Login streak continued: \(model.loginStreakCount) → \(newStreak)")
            model.loginStreakCount = newStreak
            model.lastLoginDate = Date()
            if let reward = LoginStreakService.reward(forDay: newStreak) {
                print("[UserManager] Streak milestone day \(newStreak): granting \(reward) chips")
                model.addPlayerWinning(amount: reward)
            }

        case .streakBroken:
            print("[UserManager] Login streak broken — resetting to 1")
            model.loginStreakCount = 1
            model.lastLoginDate = Date()
            // Day 1 reward
            if let reward = LoginStreakService.reward(forDay: 1) {
                model.addPlayerWinning(amount: reward)
            }
        }

        // Persist streak fields to CloudKit in the background.
        let recordId = model.id
        let newStreak = model.loginStreakCount
        let loginDate = model.lastLoginDate ?? Date()
        Task {
            do {
                try await userService.updateLoginStreak(recordId: recordId, newStreak: newStreak, loginDate: loginDate)
            } catch {
                print("[UserManager] Failed to sync login streak: \(error)")
            }
        }
    }

    func signOut() {
        // optional: clear local session; CloudKit records remain
        self.session = .unauthenticated
    }
}

enum UserSession {
    case unauthenticated
    case loading
    case authenticated(UserModel)
    case failed(String)
}

