//
//  HeaderView.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 7/24/24.
//

import Foundation
import SwiftUI

struct HeaderView: View {
    let title: String
    @ObservedObject var pageController: PageController
    
    var body: some View {
        
        HStack {
            //If the title is for the profile info
            
            HStack(spacing: 0){
                Image(systemName: "dollarsign")
                    .foregroundStyle(Color.green)

                Text("1,000,000")
                    .foregroundStyle(Color.yellow)

            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.largeTitle)
            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
            .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 0))
            
            Spacer()
            
            Text(title)
                .font(.extraLargeTitle)
                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                .padding()
                .frame(maxWidth: .infinity)
            Spacer()
            
            Image(systemName: "person.circle")
                .font(.largeTitle)
                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 30))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .onTapGesture {
                    pageController.profilePageToggle()
                    
                }
        }
    }
}
