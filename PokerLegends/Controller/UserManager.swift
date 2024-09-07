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

class UserManager: NSObject, ObservableObject {
    
    //TODO: this is just here to make sure we sign in and will need to make it turn off the loading icon when the request is finished
    @Published var isLoggedIn = false

    func signInWithApple() {
        self.isLoggedIn = true
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
}

extension UserManager: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            // Process user data, e.g., save in Keychain, and update UI
            self.isLoggedIn = true
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error
        print("Authorization failed: \(error.localizedDescription)")
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Get the current active scene
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return ASPresentationAnchor()
        }
        
        // Return the first window in the scene
        return windowScene.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
