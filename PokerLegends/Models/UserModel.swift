//
//  UserModel.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 8/10/24.
//

import Foundation


struct UserModel {
    
    //Necessary Data from logged in CloudKit
    var id = UUID()
    var username: String
    var email: String
    var isLoggedIn: Bool
    var currentMoney: Double
    var lastSignedIn: [UserDateModel]
    
    //Optional Data from logged in CloudKit
    var userImage: String?
    var gameStats: [GameStats]?
    
}
