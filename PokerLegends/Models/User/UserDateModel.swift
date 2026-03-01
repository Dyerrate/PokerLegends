//
//  UserDateModel.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 8/10/24.
//

import Foundation
//INFO: This will be for the logged in users date info that is for reward Info etc..

struct UserDateModel {
   
    var id = UUID()
    var claimedDates: [Date]?
    var claimedDatesContiuous: Int?
    var lastDateSignedIn: Date?
    
}
