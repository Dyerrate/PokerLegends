//
//  GameDisplayCard.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 7/26/24.
//The main component for the Select a Game Cards
//
import Foundation
import SwiftUI



struct GameDisplayCard: View {
    
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    var gameCardInfo: GameCardModel
    
    var body: some View {
        
        VStack {
            Image(gameCardInfo.image)
                .resizable()
            HStack {
                Label(gameCardInfo.playerCountText, systemImage: "person")
                    .font(.system(size: 25))
                    .fontWeight(.bold)
                    .padding(EdgeInsets(top: 0, leading: 30, bottom: 4, trailing: 0))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                Text(gameCardInfo.title)
                    .font(.system(size: 40))
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)

                Spacer()
                Button(action: {
                    
                    Task {
                        let resut = await openImmersiveSpace(id: "GameView")
                        print("Play to start button")
                        if case .error = resut {
                            print("There was an error opening up the current")
                        }
                    }
                    
                }) {
                    Text(gameCardInfo.buttonText)
                        .padding()
                        .foregroundColor(.green)
                        .fontWeight(.bold)
                }
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 15))
                .frame(maxWidth: .infinity, alignment: .trailing)

                
            }
        }
        .background(.black)
        
    }
}
