//
//  PokerChip.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 5/18/25.
//

import Foundation
import RealityKit


struct PokerChipModel {
    var currentEntity: Entity?
    var chipName: String
    var chipValue: Int
    var color: String
    
    init(color: String, entity: Entity?) {
           self.color = color.lowercased()
           self.currentEntity = entity

           switch self.color {
           case "green":
               self.chipValue = 100
           case "blue":
               self.chipValue = 50
           case "red":
               self.chipValue = 500
           default:
               self.chipValue = 0 // fallback
           }

           self.chipName = "\(self.color)Chip-\(UUID().uuidString.prefix(8))"
       }
}

struct PokerChipModelComponenet: Component {
    var chipValue: Int
    var hasBeenCounted: Bool = false
   
}
