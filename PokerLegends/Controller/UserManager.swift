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
  //  private let userService = CloudKitUser()

    func signIn() {
        self.session = .unauthenticated
        /*
        Task {
            do {
                let credential = try await signInService.startSignIn()
                let appleUserId = credential.user
                // Try existing user
                if let record = try await userService.fetchUser(byAppleUserId: appleUserId),
                   let currentUserModel = UserModel(record: record) {
                    self.session = .authenticated(currentUserModel)
                } else {
                    // First-time sign-in: capture name/email if available
                    let email = credential.email
                    let fullName = PersonNameComponentsFormatter().string(from: credential.fullName ?? PersonNameComponents())
                    let record = try await userService.createUser(appleUserId: appleUserId,
                                                                  email: email,
                                                                  fullName: fullName.isEmpty ? nil : fullName)
                    guard let model = UserModel(record: record) else { throw NSError(domain: "Mapping", code: -1) }
                    self.session = .authenticated(model)
                }
            } catch {
                self.session = .failed(error.localizedDescription)
            }
         
        }
         */
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

