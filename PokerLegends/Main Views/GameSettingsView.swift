//
//  GameSettingsView.swift
//  PokerLegends
//
//  Created by Samuel Dyer on 1/18/26.
//

import SwiftUI

struct GameSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var soundEnabled = true
    @State private var musicVolume: Double = 0.7
    @State private var dealerSpeed = 1
    @State private var autoPlay = false
    
    private let speedOptions = ["Slow", "Normal", "Fast"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Game Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(spacing: 20) {
                    // Sound Settings
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Audio")
                            .font(.headline)
                        
                        Toggle("Sound Effects", isOn: $soundEnabled)
                        
                        VStack {
                            HStack {
                                Text("Music Volume")
                                Spacer()
                                Text("\(Int(musicVolume * 100))%")
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: $musicVolume, in: 0...1)
                        }
                        .disabled(!soundEnabled)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Game Settings
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Gameplay")
                            .font(.headline)
                        
                        HStack {
                            Text("Dealer Speed")
                            Spacer()
                            Picker("Speed", selection: $dealerSpeed) {
                                ForEach(0..<speedOptions.count, id: \.self) { index in
                                    Text(speedOptions[index]).tag(index)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 200)
                        }
                        
                        Toggle("Auto Play Mode", isOn: $autoPlay)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        // Save settings
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    GameSettingsView()
}