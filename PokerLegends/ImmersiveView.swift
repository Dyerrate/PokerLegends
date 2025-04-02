//
//  ImmersiveView.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 6/30/24.
//

import SwiftUI
import RealityKit
import BlackJackProject

struct ImmersiveView: View {
    var body: some View {
        RealityView { content in
            // Add the initial RealityKit content
            if let scene = try? await Entity(named: "Immersive", in: blackJackProjectBundle) {
                content.add(scene)
            }
        }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
}
