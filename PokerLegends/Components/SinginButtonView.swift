//
//  SinginButtonView.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 8/10/24.
//

import Foundation
import SwiftUI
import AuthenticationServices

struct SignInWithAppleButtonView: UIViewRepresentable {
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(authorizationButtonType: .signIn, authorizationButtonStyle: .black) // Adjust style as needed
        
        // Apply any customizations to mimic visionOS buttons
        button.cornerRadius = 12 // Adjust the corner radius to match visionOS buttons
        
        // Optionally, add shadow to match visionOS button effects
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 0.2
        button.layer.shadowRadius = 8.0
        
        return button
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}
}
