//
//  RewardView.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 7/28/24.
//

import Foundation
import SwiftUI

struct RewardView: View {
    @StateObject var viewModel = RewardViewModel()
    
    var body: some View {
        
        VStack {
            HStack(spacing: 5){
                Image(systemName: "gift")
                    .fontWeight(.bold)
                    .font(.largeTitle)
                
                Text(viewModel.currentMonth)
                    .font(.extraLargeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.yellow)

                Image(systemName: "gift")
                    .fontWeight(.bold)
                    .font(.largeTitle)
            }
            LazyVGrid(columns: Array(repeating: .init(), count: 7)) {
                ForEach(viewModel.days) { day in
                    VStack {
                        let dayNumber = Calendar.current.component(.day, from: day.date)
                        Button(action: {
                            viewModel.claimReward(for: day)
                            
                        }) {
                            if day.claimed {
                                RoundedRectangle(cornerSize: CGSize(width: 20, height: 20))
                                    .fill(.clear)
                                    .frame(width: 55, height: 95)
                                    .overlay(
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.green)
                                            .font(.system(size: 40)))
                                
                            } else if dayNumber < viewModel.currentDay {
                                RoundedRectangle(cornerSize: CGSize(width: 20, height: 20))
                                    .fill(.clear) // Dark gray shade
                                    .frame(width: 55, height: 95)
                                    .overlay(
                                        Text(String(dayNumber))
                                            .font(.system(size: 40))
                                            .foregroundColor(.black) // Adjust text color for visibility
                                    )
                            } else if dayNumber == viewModel.currentDay {
                                RoundedRectangle(cornerSize: CGSize(width: 20, height: 20))
                                    .fill(.clear) // Dark gray shade
                                    .frame(width: 55, height: 95)
                                    .overlay(
                                        Text(String(dayNumber))
                                            .font(.system(size: 40))
                                            .foregroundColor(.yellow) // Adjust text color for visibility
                                    )
                            } else {
                                RoundedRectangle(cornerSize: CGSize(width: 20, height: 20))
                                    .fill(.clear)
                                    .frame(width: 55, height: 95)
                                    .overlay(
                                        Text(String(dayNumber))
                                            .font(.system(size: 40))
                                    )
                            }
                        }
                        .disabled(dayNumber < viewModel.currentDay)
                        
                    }
                    
                }
                .scaledToFit()
            }

        }
        
    }
}


#Preview(windowStyle: .automatic) {
    RewardView()
}
