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
    @EnvironmentObject var userModel: UserModel
    @State private var selectedTab = 1

    var body: some View {
        TabView(selection: $selectedTab) {
            SelectGameMode(pageController: pageController)
                .environmentObject(userModel)
                .tabItem {
                    Label("Games", systemImage: "gamecontroller")
                        
                }.tag(1)
            ShopPage(pageController: pageController)
                .environmentObject(userModel)
                .tabItem {
                    Label("Shop", systemImage: "dollarsign")
                        
                }.tag(2)
            PrizeTabView(pageController: pageController)
                .environmentObject(userModel)
                .tabItem {
                    Label("Prizes", systemImage: "gift")
                        
                }.tag(3)
            MoreInfoView(pageController: pageController)
                .environmentObject(userModel)
                .tabItem {
                    Label("Info", systemImage: "info")
                        
                }.tag(4)
        }
        .onChange(of: selectedTab) {
            pageController.hidePage()
        }
        .background {
            // Elegant light gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color(.systemBackground).opacity(0.95),
                    Color(.secondarySystemBackground).opacity(0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environmentObject(UserModel.sample)
}
