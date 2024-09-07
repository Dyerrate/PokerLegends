//
//  WelcomeDisplay.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 8/10/24.
//

import Foundation
import SwiftUI

struct WelcomeDisplay: View {
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
            ZStack {
                Image("PokerLegendsWelcomes")
                    .resizable()
                
                VStack{
                    Spacer()
                    
                    SignInWithAppleButtonView()
                        .frame(width: 450, height: 75)
                        .padding()
                        .onTapGesture {
                            userManager.signInWithApple()
                    }
                }
                
            }
    }
}
#Preview(windowStyle: .automatic) {
    WelcomeDisplay()
}
