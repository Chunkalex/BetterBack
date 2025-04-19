//  HomeView2.swift
//  BetterBack
//
//  Created by Alex Koo on 14/4/2025.
//

import SwiftUI
import CoreBluetooth

struct HomeView2: View {
    @EnvironmentObject var bleViewModel: BluetoothViewModel
    
    
    var body: some View {
        NavigationView {
            
            VStack { // Command buttons section.
                Text("Select a Command:")
                    .font(.headline)
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        ForEach(1...5, id: \.self) { number in
                            Button(action: {
                                sendCommand(number)
                            }) {
                                Text("\(number)")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    HStack(spacing: 10) {
                        ForEach(6...10, id: \.self) { number in
                            Button(action: {
                                sendCommand(number)
                            }) {
                                Text("\(number)")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .padding()
        }
    }
    
    /// Helper function to send a command as BLE data.
    private func sendCommand(_ command: Int) {
        let commandString = "\(command)"
        if let data = commandString.data(using: .utf8) {
            bleViewModel.sendData(data)
        } else {
            print("Failed to encode command \(command)")
        }
    }
}

    
    


