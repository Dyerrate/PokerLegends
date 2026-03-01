//
//  ShoppingItemModel.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 7/27/24.
//

import Foundation
import SwiftUI

struct ShoppingItemModel: Identifiable {
    var id = UUID()
    var price: Double
    var title: String
    var image: String

}

struct ShoppingTestData {
    static let shoppingItemData = [ShoppingItemModel(price: 1.99, title: "Small Buy In", image: "smallBuy"), ShoppingItemModel(price: 4.99, title: "Medium Buy In", image: "mediumBuy"), ShoppingItemModel(price: 9.99, title: "Large Buy In", image: "largeBuy"), ShoppingItemModel(price: 19.99, title: "Baller Buy In", image: "bigBaller")]
    
}
