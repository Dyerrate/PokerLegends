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
                await MainActor.run { self.session = .authenticated(model) }
            } catch {
                print("[UserManager] signIn failed with error: \(error)")
                await MainActor.run { self.session = .failed(error.localizedDescription) }
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

