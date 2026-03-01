//
//  MainView.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 8/19/24.
//

import Foundation
import SwiftUI

struct MainView: View {
    
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var userModel: UserModel
    
    var body: some View {
            switch userManager.session {
            case .loading:
                Text("loading phase")
                //ProgressView("Signing in…")
            case .unauthenticated:
                VStack(spacing: 16) {
                    WelcomeDisplay(userManager: _userManager)
                    Button("Sign In (Test User)") {
                        // Temporarily authenticate with a sample user for testing
                        // Assumes `userManager.session` is a writable enum with an `.authenticated(UserModel)` case
                        userManager.session = .authenticated(UserModel.sample)
                    }
                }
                .padding()
            case .failed(let message):
                VStack(spacing: 16) {
                    Text("Sign-in failed")
                        .font(.headline)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Try Again") {
                        userManager.signIn()
                    }
                }
                .padding()
            case .authenticated(let user):
                // Pass the signed-in user to your app's content
                ContentView()
                    .environmentObject(user)
            }
    }
}

