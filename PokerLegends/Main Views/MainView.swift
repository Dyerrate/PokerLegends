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
    
    var body: some View {
        
        if userManager.isLoggedIn {
            ContentView()
        } else {
            WelcomeDisplay(userManager: _userManager )
        }
    }
}

