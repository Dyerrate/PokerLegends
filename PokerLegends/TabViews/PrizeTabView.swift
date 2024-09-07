//
//  PrizeTabView.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 7/27/24.
//

import Foundation
import SwiftUI
//TODO: Add prizes in a calendar view for the user to know when they signed in and  claimed their prizes(free chips)

struct PrizeTabView: View {
    
    @ObservedObject var pageController: PageController

    var body: some View {
        NavigationStack {
            VStack{
                HeaderView(title: "Claim Chips", pageController: pageController)
                Spacer()
                
                
                RewardView()
                Spacer()
                
            }
            .navigationDestination(isPresented: $pageController.profilePage) {
                ProfileView(pageController: pageController)
                    .navigationTitle("My Legend")
                    .navigationBarTitleDisplayMode(.large)
                
            }
        }
    }
}
