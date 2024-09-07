//
//  ProfileView.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 8/10/24.
//

import Foundation
import SwiftUI

struct ProfileView: View {
    
    @ObservedObject var pageController: PageController
    
    //TODO: Add User model data to this to populate the information for each box
    var body: some View {
        
        VStack(spacing: 30) {
            Spacer()
            VStack(spacing: 20) {
                Circle()
                    .fill(Color.black)
                    .frame(width: 100, height: 100)
                Text("Yournamehere")
                    .font(.title2)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.systemGray5))
            .cornerRadius(10)
            
            //Quarter Boxes
            VStack(spacing: 10) {
                
                //Winnings Box
                HStack(spacing: 10) {
                    HStack {
                        HStack {
                            Image(systemName: "suit.spade")
                                .padding()
                            Spacer()
                        }
                        VStack {
                            Text("Total Winnings")
                                .underline()
                                .font(.title2)
                            Text("$1,000,000")
                        }
                        .padding()
                        HStack {
                            Spacer()
                            Image(systemName: "suit.spade")
                                .padding()
                        }
                        
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.systemGray4))
                    .cornerRadius(10)
                    
                    //Total Losses
                    HStack{
                        HStack{
                            Image(systemName: "suit.heart")
                                .padding()
                            Spacer()
                        }
                        VStack {
                            Text("Total Losses")
                                .underline()
                                .font(.title2)
                            Text("$1,000,000")
                        }
                        .padding()
                        HStack{
                            Spacer()
                            Image(systemName: "suit.heart")
                                .padding()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.systemGray4))
                    .cornerRadius(10)
                }
                
                //Largest Wining
                HStack(spacing: 10) {
                    HStack{
                        HStack{
                            Image(systemName: "suit.club")
                                .padding()
                            Spacer()
                        }
                        VStack {
                            Text("Largest Hand")
                                .underline()
                                .font(.title2)
                            Text("$1,000,000,000")
                        }
                        .padding()
                        HStack{
                            Spacer()
                            Image(systemName: "suit.club")
                                .padding()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.systemGray4))
                    .cornerRadius(10)
                    
                    //All In's in all gamemodes
                    HStack{
                        HStack{
                            Image(systemName: "suit.diamond")
                                .padding()
                            Spacer()
                        }
                        VStack {
                            Text("All in's")
                                .underline()
                                .font(.title2)
                            Text("482")
                        }
                        .padding()
                        HStack{
                            Spacer()
                            Image(systemName: "suit.diamond")
                                .padding()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.systemGray4))
                    .cornerRadius(10)
                }
            }
            Spacer()
            Button(action: {
                // Sign out action
            }) {
                Text("Sign Out")
                    .font(.headline)
                    .padding()
                    .cornerRadius(10)
            }
            .frame(maxWidth: .infinity)
            
            
        }
        .padding()
        .cornerRadius(15)
        .padding()
    }
    
}

