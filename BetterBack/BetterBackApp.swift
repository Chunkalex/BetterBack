//
//  BetterBackApp.swift
//  BetterBack
//
//  Created by Alex Koo on 31/3/2025.
//
import SwiftUI

@main
struct BetterBackApp: App {
    @StateObject private var bleViewModel = BluetoothViewModel()

    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(bleViewModel)

        }
    }
}
