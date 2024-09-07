//
//  ShoppingItemCard.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 7/27/24.
//

import Foundation
import SwiftUI

struct ShoppingItemCard: View {
    
    var shoppingItemInfo: ShoppingItemModel
    
    var body: some View {
        VStack {
            Image(shoppingItemInfo.image)
                .resizable()
            
            HStack {
                HStack(spacing: 0){
                    Text("$")
                    Text(String(shoppingItemInfo.price))
                }
                .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 0))
                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                Text(shoppingItemInfo.title)
                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                    .frame(maxWidth: .infinity)
                
                Spacer()
                Button(action: {
                    print("Buy")
                    //TODO: Add apply pay logic
                }) {
                    Label("Pay", systemImage: "apple.logo")
                        .padding()
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                }   
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 15))
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 0))
        }
        .background(Color.black)
    }
}
