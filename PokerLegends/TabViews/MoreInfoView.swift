//
//  MoreInfoView.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 7/24/24.
//

import Foundation
import SwiftUI
//TODO: Add info page about how to navigate / invite friends etc

struct MoreInfoView: View {
    @ObservedObject var pageController: PageController
    
    var body: some View {
        NavigationStack {
            VStack{
                
                HeaderView(title: "More Info", pageController: pageController)
                Spacer()
                HStack(spacing: 0){
                    Spacer()
                    InfoPanel(panelNumber: 1, panelInfoText: "Select a Table", imageName: "racoonGame")
                    Spacer()
                    Image(systemName: "arrow.forward")
                        .font(.extraLargeTitle2)
                        .scaleEffect(1.75)
                    Spacer()
                    InfoPanel(panelNumber: 2, panelInfoText: "Invite friends!", imageName: "dogGame")
                    Spacer()
                    Image(systemName: "arrow.forward")
                        .font(.extraLargeTitle2)
                        .scaleEffect(1.75)
                    Spacer()
                    InfoPanel(panelNumber: 3, panelInfoText: "Gamble, Win, Repeat ", imageName: "catPng")
                    Spacer()
                }
                Spacer()
                RoundedRectangle(cornerSize: CGSize(width: 20, height: 20))
                    .fill(Color.gray)
                    .frame(width: 550, height: 65)
                    .overlay(
                        VStack(spacing: 5) {
                            Text("For a video guide click")
                                .foregroundStyle(Color.black)
                            
                            Link("here", destination: URL(string: "https://www.youtube.com/watch?v=zLFyKG3qFzw")!)
                            
                        }
                    )
                
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



