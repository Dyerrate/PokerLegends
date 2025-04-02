//
//  Game.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 9/28/24.
//

import TabletopKit
import RealityKit
import SwiftUI

//We will need to make files for each type of table we need similar to the 'Game' below this. So for black jack, poker, we need to make seperate classes for each but set to the GameProtocal so its stating that these are needed when we create a game and will all be seperate.
protocol GameProtocol {
    var tabletopGame: TabletopGame { get }
    var renderer: GameRenderer { get }
    var observer: GameObserver { get }
    var setup: GameSetup { get }
    func resetGame()
}
