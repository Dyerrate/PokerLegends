//
//  ContentView.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 6/30/24.
//

import SwiftUI
import RealityKit

//TODO: Make sure that all ui is scalable and work to test resizing issues
struct ContentView: View {

    @StateObject var pageController = PageController()
    @State private var selectedTab = 1

    var body: some View {
        TabView(selection: $selectedTab) {
            SelectGameMode(pageController: pageController)
                .tabItem {
                    Label("Games", systemImage: "gamecontroller")
                        
                }.tag(1)
            ShopPage(pageController: pageController)
                .tabItem {
                    Label("Shop", systemImage: "dollarsign")
                        
                }.tag(2)
            PrizeTabView(pageController: pageController)
                .tabItem {
                    Label("Prizes", systemImage: "gift")
                        
                }.tag(3)
            MoreInfoView(pageController: pageController)
                .tabItem {
                    Label("Info", systemImage: "info")
                        
                }.tag(4)
        }.onChange(of: selectedTab) {
            pageController.hidePage()
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
