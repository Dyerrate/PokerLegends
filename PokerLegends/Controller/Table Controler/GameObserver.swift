//
//  GameObserver.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 10/6/24.
//

import RealityKit
import TabletopKit
import SwiftUI


class GameObserver: TabletopGame.Observer {
    let tabletop: TabletopGame
    let renderer: GameRenderer
    var gameToRender: String
    
    init(tabletop: TabletopGame, renderer: GameRenderer, gameToRender: String) {
        self.tabletop = tabletop
        self.renderer = renderer
        self.gameToRender = gameToRender
    }


    
    func playerChangedSeats(_ player: Player, oldSeat: (any TableSeat)?, newSeat: (any TableSeat)?, snapshot: TableSnapshot) {
        if player.id == tabletop.localPlayer.id, newSeat == nil {
            tabletop.claimAnySeat()
        }
    }
}
