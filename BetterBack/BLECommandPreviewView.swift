import SwiftUI
import CoreBluetooth

struct BLECommandPreviewView: View {
    @EnvironmentObject var bleViewModel: BluetoothViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                // Display the current connection status.
                Text(bleViewModel.connectionStatus)
                    .padding()
                
                // List discovered peripherals for the user to connect.
                List(bleViewModel.discoveredPeripherals, id: \.identifier) { peripheral in
                    Button(action: {
                        bleViewModel.connect(to: peripheral)
                    }) {
                        Text(peripheral.name ?? "Unnamed Device")
                    }
                }
                .listStyle(PlainListStyle())
                .navigationTitle("Choose your device")
                
                Divider()
                    .padding(.vertical)
                
                
                
      
            }

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
