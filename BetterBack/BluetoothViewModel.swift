import SwiftUI
import CoreBluetooth

// MARK: - BluetoothViewModel
class BluetoothViewModel: NSObject, ObservableObject {
    // Published properties to update the UI.
    @Published var discoveredPeripherals: [CBPeripheral] = []
    @Published var connectionStatus: String = "Not Connected"
    @Published var calibrationResponse: String? = nil  // Calibration feedback

    // The connected peripheral and its writable characteristic.
    var connectedPeripheral: CBPeripheral?
    var writableCharacteristic: CBCharacteristic?
    
    // The central manager for BLE.
    private var centralManager: CBCentralManager?
    
    override init() {
        super.init()
        // Initialize the central manager on the main queue.
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
    }
    
    /// Connects to the selected peripheral.
    func connect(to peripheral: CBPeripheral) {
        connectionStatus = "Connecting to \(peripheral.name ?? "unnamed device")..."
        // Set the peripheral delegate immediately.
        peripheral.delegate = self
        // Store the peripheral so it is shared among all views.
        connectedPeripheral = peripheral
        centralManager?.connect(peripheral, options: nil)
    }
    
    /// Sends data to the BLE device using a writable characteristic.
    func sendData(_ data: Data) {
        guard let peripheral = connectedPeripheral,
              let characteristic = writableCharacteristic else {
            print("No connected peripheral or writable characteristic available")
            return
        }
        // Write the data using .withResponse for acknowledgement.
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
        print("Sent data: \(data)")
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothViewModel: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            // Start scanning for peripherals when Bluetooth is ready.
            central.scanForPeripherals(withServices: nil, options: nil)
        default:
            connectionStatus = "Bluetooth not available: \(central.state)"
            print("Bluetooth state: \(central.state)")
        }
    }
    
    // Called for each discovered peripheral.
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "Unnamed Device"
        print("Discovered device: \(localName)")
        if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            if let _ = peripheral.name {
                discoveredPeripherals.append(peripheral)
            }
        }
    }
    
    // Called when a peripheral is successfully connected.
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectionStatus = "Connected to \(peripheral.name ?? "unnamed device")"
        // confirmed assignment:
        connectedPeripheral = peripheral
        peripheral.delegate = self
        // Stop scanning once connected.
        central.stopScan()
        // Start discovering services.
        peripheral.discoverServices(nil)
    }
    
    // Called if the connection fails.
    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        connectionStatus = "Failed to connect to \(peripheral.name ?? "unnamed device")"
        print("Failed to connect: \(error?.localizedDescription ?? "Unknown error")")
    }
}

// MARK: - CBPeripheralDelegate
extension BluetoothViewModel: CBPeripheralDelegate {
    // Discover services on the connected peripheral.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        guard let services = peripheral.services else { return }
        for service in services {
            print("Discovered service: \(service.uuid) for \(peripheral.name ?? "unnamed device")")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    // Called when characteristics are discovered for a given service.
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            return
        }
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            print("Discovered characteristic: \(characteristic.uuid) for service: \(service.uuid)")
            // Subscribe to notifications if supported.
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
            // Save the writable characteristic.
            if characteristic.properties.contains(.write) ||
                characteristic.properties.contains(.writeWithoutResponse) {
                writableCharacteristic = characteristic
                print("Writable characteristic found: \(characteristic.uuid)")
            }
        }
    }
}
