//
//  GameToolBar.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 10/5/24.
//

import Foundation
import SwiftUI
import TabletopKit
import RealityKit


struct GameToolBar: ToolbarContent {

    let game: GameProtocol
    
    
    
    init(game: GameProtocol) {
        
        print("cheeks")
        self.game = game
    }
    
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomOrnament) {
            Button("Reset", systemImage: "arrow.counterclockwise") {
                game.resetGame()
            }
            Spacer()
            Button("SharePlay", systemImage: "shareplay") {
               Task {
                    try! await Activity().activate()
               }
            }
        }
    }
}
