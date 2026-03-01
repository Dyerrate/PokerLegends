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
    @EnvironmentObject var userModel: UserModel
    
    private var formattedMoney: String {
        guard let money = userModel.playerMoney else {
            return "0"
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: money)) ?? "0.00"
    }
    
    var body: some View {
        
        HStack {
            //If the title is for the profile info
            
            HStack(spacing: 0){
                Image(systemName: "dollarsign")
                    .foregroundStyle(Color.green)

                Text(formattedMoney)
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
            
            Button {
                pageController.profilePageToggle()
            } label: {
                Image(systemName: "person.circle")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(10) // inner padding for touch target
            }
            .buttonStyle(.plain) // keep custom look
            .background(
                // Use a translucent material for a glass feel on visionOS
                .thinMaterial
            )
            .clipShape(Capsule())
            .contentShape(Capsule()) // improves hit testing
            .hoverEffect(.lift) // nice depth on hover in visionOS
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 30))
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}
