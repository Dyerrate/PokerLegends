//
//  InfoPanel.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 8/3/24.
//

import Foundation
import SwiftUI

struct InfoPanel: View {
    
    var panelNumber: Int
    var panelInfoText: String
    var imageName: String
    
    var body: some View {
        
        VStack {
            Text(String(panelNumber))
                .font(.system(size: 20))
                .fontWeight(.bold)
                .background(Circle()
                    .fill(Color.gray)
                    .frame(width: 50, height: 50))
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 20, trailing: 0))
            
            Image(imageName)
                .resizable()
            //  .aspectRatio(contentMode: .fill)
                .clipShape(RoundedRectangle(cornerSize: CGSize(width: 20, height: 20)))
                .overlay(
                    RoundedRectangle(cornerSize: CGSize(width: 20, height: 20))
                        .stroke(Color.white, lineWidth: 4)
                )
                .overlay(
                    Text(panelInfoText)
                        .font(.system(size: 30))
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                )
                .padding()
        }
        .foregroundStyle(.white)
    }
}


