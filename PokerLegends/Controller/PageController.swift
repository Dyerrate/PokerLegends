//
//  PageController.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 8/10/24.
//

import Foundation
import SwiftUI

class PageController: NSObject, ObservableObject {
    
    @StateObject var userManager = UserManager()
    @Published var isLoading = false
    @Published var profilePage = false

    
    func startLoading() {
        self.isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                self.isLoading = false
            }
    }
    
    func hidePage() {
        self.profilePage = false
    }
    
    func profilePageToggle() {
        self.profilePage.toggle()
        print("toggled: \(self.profilePage)")
    }
}
