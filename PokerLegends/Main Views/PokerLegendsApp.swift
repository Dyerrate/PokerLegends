//
//  PokerLegendsApp.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 6/30/24.
//

import SwiftUI

@main
struct PokerLegendsApp: App {
    var body: some Scene {
        WindowGroup(id: "MainView") {
           // ContentView()
            MainView()
                .frame (minWidth: 1200, maxWidth: 1280, minHeight: 650, maxHeight: 900)

        }
        .windowResizability(.contentSize)

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }
    }
}
