//  MainTabView.swift
//  BetterBack
//
//  Created by Alex Koo on 31/3/2025.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            VibrationView()
                .tabItem {
                    Label("VibrationView", systemImage: "waveform.path.ecg")
                }
            
            CalibrationView()
                .tabItem {
                    Label("Calibration", systemImage: "slider.horizontal.3")
                }
            
            BLECommandPreviewView()
                .tabItem {
                    Label("Initialization", systemImage: "chart.bar")
                }
            

             
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(BluetoothViewModel())
    }
}

///////////////////////
