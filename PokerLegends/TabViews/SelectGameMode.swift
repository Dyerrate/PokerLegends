//
//  SelectGameMode.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 7/23/24.
//

import Foundation
import SwiftUI

struct SelectGameMode: View {
    let gameCards = GameData.gameCardData
    @ObservedObject var pageController: PageController


    var body: some View {
        NavigationStack {
            VStack {
                HeaderView(title: "Select a Game", pageController: pageController)
                Spacer()
                ScrollView(.vertical) {
                    VStack {
                        ForEach(gameCards) { card in
                            GameDisplayCard(gameCardInfo: card)
                                .frame(width: 1000, height: 600)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .scaledToFit()
                                .padding(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $pageController.profilePage) {
                ProfileView(pageController: pageController)
                    .navigationTitle("My Legend")
                    .navigationBarTitleDisplayMode(.large)
            }

        }
    }
}
