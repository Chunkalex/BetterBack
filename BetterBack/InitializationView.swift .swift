//  InitializationView.swift .swift
//  BetterBack
//
//  Created by Alex Koo on 31/3/2025.
//

import SwiftUI
import CoreBluetooth

struct InitializationView: View {
    @StateObject private var bleViewModel = BluetoothViewModel()

    var body: some View {
        NavigationView {
            VStack {
                Text("Add a new BetterBack device to start")
                    .font(.title)
                    .padding(.horizontal)
                    .padding(.top, 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(bleViewModel.connectionStatus)
                    .padding()
                
                List(bleViewModel.discoveredPeripherals, id: \.identifier) { peripheral in
                    Button(action: {
                        bleViewModel.connect(to: peripheral)
                    }) {
                        Text(peripheral.name ?? "Unnamed Device")
                    }
                }
                .listStyle(PlainListStyle())
                
                Spacer()
            }
            .navigationTitle("Initialization")
        }
    }
}

struct InitializationView_Previews: PreviewProvider {
    static var previews: some View {
        InitializationView()
    }
}
