//
//  ShopPage.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 7/23/24.
//

import Foundation
import SwiftUI

struct ShopPage: View {
    var shoppingItemCardList = ShoppingTestData.shoppingItemData
    @ObservedObject var pageController: PageController

    var body: some View {
        NavigationStack {
            VStack {
                HeaderView(title: "Buy Chips", pageController: pageController)
                Spacer()
                ScrollView(.horizontal) {
                    HStack{
                        ForEach(shoppingItemCardList) { card in
                            ShoppingItemCard(shoppingItemInfo: card)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .scaledToFit()
                                .padding(EdgeInsets(top:0, leading:20, bottom: 20, trailing: 20))
                        }
                    }
                }
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
