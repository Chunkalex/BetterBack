import SwiftUI
import CoreBluetooth // if needed by BluetoothViewModel

// MARK: - Custom Discrete Slider with Tick Marks
struct DiscreteTickSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let tickLabels: [String]  // e.g., ["Slow", "Medium", "Fast"]

    var body: some View {
        VStack(spacing: 4) {
            Slider(value: $value, in: range, step: step)
                .padding(.horizontal)
            GeometryReader { geometry in
                let sliderWidth = geometry.size.width
                HStack(spacing: 0) {
                    ForEach(0..<tickLabels.count, id: \.self) { index in
                        VStack(spacing: 2) {
                            Rectangle()
                                .fill(Color.gray)
                                .frame(width: 1, height: 10)
                            Text(tickLabels[index])
                                .font(.caption)
                        }
                        .frame(width: sliderWidth / CGFloat(tickLabels.count), alignment: .center)
                    }
                }
            }
            .frame(height: 20)
            .padding(.horizontal, -53) // Adjust as needed for alignment
        }
    }
}

// MARK: - VibrationView with Custom Bindings for Debouncing Commands
struct VibrationView: View {
    // MARK: - Bluetooth ViewModel Instance
    @EnvironmentObject var bleViewModel: BluetoothViewModel

    // MARK: - Tolerance Time State
    let toleranceOptions: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    @State private var selectedToleranceIndex: Int = 0

    // For manual tolerance input.
    @State private var manualToleranceSeconds: Double = 0
    @State private var showManualToleranceSheet: Bool = false

    // MARK: - Vibration Settings State (0: Slow, 1: Medium, 2: Fast)
    @State private var roundedShoulderVibration: Double = 1
    @State private var spineTiltingVibration: Double = 1

    // Debounce work items to cancel repeated command sending
    @State private var toleranceDebounceWorkItem: DispatchWorkItem?
    @State private var roundedShoulderDebounceWorkItem: DispatchWorkItem?
    @State private var spineTiltingDebounceWorkItem: DispatchWorkItem?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {

                    // Tolerance Time Section
                    Text("Tolerance Time")
                        .font(.headline)
                        .padding(.horizontal)

                    Text("Set the duration of your device after detecting poor posture. This setting prevents unnecessary alerts for brief deviations.")
                        .font(.subheadline)
                        .padding(.horizontal)

                    // Preset tolerance options using a segmented picker
                    Picker("Tolerance Time", selection: Binding(
                        get: { toleranceOptions[selectedToleranceIndex] },
                        set: { newValue in
                            if let index = toleranceOptions.firstIndex(of: newValue) {
                                selectedToleranceIndex = index
                                toleranceDebounceWorkItem?.cancel()
                                let workItem = DispatchWorkItem {
                                    sendToleranceCommand(seconds: newValue)
                                }
                                toleranceDebounceWorkItem = workItem
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
                            }
                        }
                    )) {
                        ForEach(toleranceOptions, id: \.self) { value in
                            Text(timeDisplay(for: value)).tag(value)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                   
                    Text("Manual Tolerance: \(selectedToleranceIndex) seconds")
                        .font(.caption)
                        .padding(.horizontal, 10)

                    Divider()
                        .padding(.horizontal, 10)

                    // Vibration Settings Section
                    Text("Vibration Settings")
                        .font(.headline)
                        .padding(.horizontal)

                    Text("Set pulse lengths for different reminding modes.")
                        .font(.subheadline)
                        .padding(.horizontal)

                    // Rounded Shoulder Vibration Setting using DiscreteTickSlider with custom binding.
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Rounded Shoulder")
                            .font(.subheadline)
                            .padding(.horizontal)
                        DiscreteTickSlider(value: roundedShoulderBinding,
                                           range: 1...3,
                                           step: 1,
                                           tickLabels: ["Slow", "Medium", "Fast"])
                    }

                    // Spine Tilting Vibration Setting using DiscreteTickSlider with custom binding.
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Spine Tilting")
                            .font(.subheadline)
                            .padding(.horizontal)
                        DiscreteTickSlider(value: spineTiltingBinding,
                                           range: 1...3,
                                           step: 1,
                                           tickLabels: ["Slow", "Medium", "Fast"])
                    }

                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle("Vibration")
        }
    }

    // MARK: - Custom Debounced Bindings
    
    private var roundedShoulderBinding: Binding<Double> {
        Binding(
            get: { roundedShoulderVibration },
            set: { newValue in
                roundedShoulderVibration = newValue
                roundedShoulderDebounceWorkItem?.cancel()
                let workItem = DispatchWorkItem {
                    sendRoundedShoulderCommand(newValue)
                }
                roundedShoulderDebounceWorkItem = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
            }
        )
    }
    
    private var spineTiltingBinding: Binding<Double> {
        Binding(
            get: { spineTiltingVibration },
            set: { newValue in
                spineTiltingVibration = newValue
                spineTiltingDebounceWorkItem?.cancel()
                let workItem = DispatchWorkItem {
                    sendSpineTiltingCommand(newValue)
                }
                spineTiltingDebounceWorkItem = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
            }
        )
    }

    // MARK: - Helper Functions
     
    /// Converts a tolerance option in seconds to a display string.
    private func timeDisplay(for seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else if seconds == 60 {
            return "1min"
        } else if seconds == 120 {
            return "2min"
        } else {
            return "\(seconds)s"
        }
    }
    
    /// Formats a given time (in seconds) into a string displaying minutes and seconds.
    private func formattedTime(_ seconds: Double) -> String {
        if seconds < 60 {
            return "\(Int(seconds))s"
        } else {
            let minutes = Int(seconds) / 60
            let remainingSeconds = Int(seconds) % 60
            return remainingSeconds == 0 ? "\(minutes)min" : "\(minutes)min \(remainingSeconds)s"
        }
    }
    
    /// Sends a command with the given tolerance in seconds.
    private func sendToleranceCommand(seconds: Int) {
        let commandString = "l\(seconds)"
        print(commandString)
        if let data = commandString.data(using: .utf8) {
            bleViewModel.sendData(data)
        } else {
            print("Failed to encode tolerance command for seconds: \(seconds)")
        }
    }
    
    /// Sends a command for Rounded Shoulder vibration sensitivity.
    private func sendRoundedShoulderCommand(_ sensitivity: Double) {
        let commandString = "j\(Int(sensitivity))"
        print(commandString)
        if let data = commandString.data(using: .utf8) {
            bleViewModel.sendData(data)
        } else {
            print("Failed to encode rounded shoulder command for sensitivity: \(sensitivity)")
        }
    }
    
    /// Sends a command for Spine Tilting vibration sensitivity.
    private func sendSpineTiltingCommand(_ sensitivity: Double) {
        let commandString = "k\(Int(sensitivity))"
        print(commandString)
        if let data = commandString.data(using: .utf8) {
            bleViewModel.sendData(data)
        } else {
            print("Failed to encode spine tilting command for sensitivity: \(sensitivity)")
        }
    }
}




struct VibrationView_Previews: PreviewProvider {
    static var previews: some View {
        VibrationView()
            .environmentObject((BluetoothViewModel()))

    }
}
