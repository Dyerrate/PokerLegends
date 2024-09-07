//
//  MainView.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 8/19/24.
//

import Foundation
import SwiftUI

struct MainView: View {
    
    @StateObject var userManager = UserManager()
    @StateObject var pageController = PageController()
    
    var body: some View {
        
        if userManager.isLoggedIn {
            ContentView()
        } else {
            WelcomeDisplay()
                .environmentObject(userManager)
                .environmentObject(pageController)
        }
    }
}
