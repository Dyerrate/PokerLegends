//
//  RewardViewModel.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 7/28/24.
//

import Foundation
import SwiftUI

struct Day: Identifiable {
    var id = UUID()
    var date: Date
    var claimed: Bool = false
}

class RewardViewModel: ObservableObject {
    @Published var days: [Day] = []
    @Published var currentMonth: String
    @Published var currentDay: Int
    
    
    init() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        
        let calendar = Calendar.current
        currentMonth = dateFormatter.string(from: Date())
        currentDay = calendar.component(.day, from: Date())
        let range = calendar.range(of: .day, in: .month, for: Date())!
        let startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        
        for i in range {
            if let date = calendar.date(byAdding: .day, value: i - 1, to: startDate) {
                days.append(Day(date: date))
            }
        }
    }
    
    func claimReward(for day: Day) {
        if let index = days.firstIndex(where: { $0.id == day.id }) {
            let calendar = Calendar.current
            let currentDate = calendar.startOfDay(for: Date()) // Current date without time
            let rewardDate = calendar.startOfDay(for: days[index].date) // Reward date without time

            if currentDate == rewardDate {
                days[index].claimed = true
            }
        }
    }
}
