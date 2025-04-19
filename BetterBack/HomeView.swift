import SwiftUI

struct HomeView: View {
    // Battery level state variable.
    @State private var batteryLevel: Double = 0.7
    
    // Temporarily disable reminder state variables.
    @State private var showDisableReminderSheet = false
    @State private var isReminderDisabled = false
    @State private var reminderDisabledUntil: Date? = nil
    
    // State for Rounded Shoulder mode.
    @State private var isRoundedShoulderOn: Bool = false
    @State private var roundedShoulderSensitivity: Double = 5
    
    // State for Spine Tilting mode.
    @State private var isSpineTiltingOn: Bool = false
    @State private var spineTiltingSensitivity: Double = 5
    
    // Debounce work items for sensitivity commands.
    @State private var debounceWorkItemRounded: DispatchWorkItem?
    @State private var debounceWorkItemSpine: DispatchWorkItem?
    
    // Use a shared instance of BluetoothViewModel from the environment.
    @EnvironmentObject var bleViewModel: BluetoothViewModel
    
    // New state for disable reminder: one Picker showing preset durations (in seconds)
    @State private var selectedDuration: TimeInterval = 30  // default value
    
    // Preset durations array in seconds.
    private let durations: [TimeInterval] = [30, 60, 120, 180, 300, 600, 900, 1200, 1800]
    
    // MARK: - Custom Bindings for Toggles
    
    private var roundedShoulderOnBinding: Binding<Bool> {
        Binding(
            get: { self.isRoundedShoulderOn },
            set: { newValue in
                self.isRoundedShoulderOn = newValue
                let commandString = "d\(newValue ? 1 : 0)"
                print(commandString)
                if let data = commandString.data(using: .utf8) {
                    bleViewModel.sendData(data)
                }
            }
        )
    }
    
    private var spineTiltingOnBinding: Binding<Bool> {
        Binding(
            get: { self.isSpineTiltingOn },
            set: { newValue in
                self.isSpineTiltingOn = newValue
                let commandString = "e\(newValue ? 1 : 0)"
                print(commandString)
                if let data = commandString.data(using: .utf8) {
                    bleViewModel.sendData(data)
                }
            }
        )
    }
    
    // MARK: - Custom Bindings for Sensitivity with Debounce
    
    private var roundedShoulderSensitivityBinding: Binding<Double> {
        Binding(
            get: { self.roundedShoulderSensitivity },
            set: { newValue in
                self.roundedShoulderSensitivity = newValue
                debounceRoundedShoulderCommand(newValue)
            }
        )
    }
    
    private var spineTiltingSensitivityBinding: Binding<Double> {
        Binding(
            get: { self.spineTiltingSensitivity },
            set: { newValue in
                self.spineTiltingSensitivity = newValue
                debounceSpineTiltingCommand(newValue)
            }
        )
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 21) {
                    
                    // BatteryView at the top.
                    BatteryView(batterylevel: $batteryLevel, fill: .green, outline: .black)
                        .padding(.horizontal)
                    
                    // Temporarily Disable Reminder Section.
                    Button(action: {
                        showDisableReminderSheet = true
                    }) {
                        Text("Temporarily Disable Reminder")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    if isReminderDisabled, let until = reminderDisabledUntil, until > Date() {
                        Text("Reminder disabled until \(formattedDate(until))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    } else {
                        Text("The device is enabled")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Reminding Mode Section.
                    Text("Reminding Mode")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // Rounded Shoulder Section.
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Rounded Shoulder", isOn: roundedShoulderOnBinding)
                            .toggleStyle(SwitchToggleStyle(tint: Color.blue))
                            .padding(.vertical)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Sensitivity: \(Int(roundedShoulderSensitivity))")
                                .font(.subheadline)
                                .padding(.horizontal)
                            Slider(value: roundedShoulderSensitivityBinding, in: 1...10, step: 1)
                                .padding(.horizontal)
                        }
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Spine Tilting Section.
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Spine Tilting", isOn: spineTiltingOnBinding)
                            .toggleStyle(SwitchToggleStyle(tint: Color.blue))
                            .padding(.vertical)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Sensitivity: \(Int(spineTiltingSensitivity))")
                                .font(.subheadline)
                                .padding(.horizontal)
                            Slider(value: spineTiltingSensitivityBinding, in: 1...10, step: 1)
                                .padding(.horizontal)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle("Home")
            .sheet(isPresented: $showDisableReminderSheet) {
                DisableReminderSheet(selectedDuration: $selectedDuration, disableAction: {
                    // Set reminder disabled
                    isReminderDisabled = true
                    reminderDisabledUntil = Calendar.current.date(byAdding: .second, value: Int(selectedDuration), to: Date())
                    showDisableReminderSheet = false
                    
                    // Map the selected duration to a command value:
                    // Find the index of the selected duration in the array and add 1.
                    if let index = durations.firstIndex(where: { $0 == selectedDuration }) {
                        let commandValue = index + 1
                        let commandString = "c\(commandValue)"
                        print("Sending: \(commandString)")
                        if let data = commandString.data(using: .utf8) {
                            bleViewModel.sendData(data)
                        }
                    } else {
                        print("Selected duration not found in mapping")
                    }
                })
            }
            // Timer to check every second if the disable period has expired.
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                if isReminderDisabled, let until = reminderDisabledUntil, Date() >= until {
                    isReminderDisabled = false
                    reminderDisabledUntil = nil
                    print("Reminder has been re-enabled")
                }
            }
        }
    }
    
    // MARK: - Debounce Functions for Sensitivity Commands
    
    private func debounceRoundedShoulderCommand(_ sensitivity: Double) {
        debounceWorkItemRounded?.cancel()
        let workItem = DispatchWorkItem {
            sendRoundedShoulderCommand(sensitivity)
        }
        debounceWorkItemRounded = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.13, execute: workItem)
    }
    
    private func debounceSpineTiltingCommand(_ sensitivity: Double) {
        debounceWorkItemSpine?.cancel()
        let workItem = DispatchWorkItem {
            sendSpineTiltingCommand(sensitivity)
        }
        debounceWorkItemSpine = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.13, execute: workItem)
    }
    
    // MARK: - Helper Functions
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func sendRoundedShoulderCommand(_ sensitivity: Double) {
        let commandString = "f\(Int(sensitivity))"
        print(commandString)
        if let data = commandString.data(using: .utf8) {
            bleViewModel.sendData(data)
        } else {
            print("Failed to encode rounded shoulder command for sensitivity: \(sensitivity)")
        }
    }
    
    private func sendSpineTiltingCommand(_ sensitivity: Double) {
        let commandString = "g\(Int(sensitivity))"
        print(commandString)
        if let data = commandString.data(using: .utf8) {
            bleViewModel.sendData(data)
        } else {
            print("Failed to encode spine tilting command for sensitivity: \(sensitivity)")
        }
    }
    
    private func sendCommand(_ command: Int) {
        let commandString = "\(command)"
        if let data = commandString.data(using: .utf8) {
            bleViewModel.sendData(data)
        } else {
            print("Failed to encode command \(command)")
        }
    }
}

struct DisableReminderSheet: View {
    @Binding var selectedDuration: TimeInterval
    var disableAction: () -> Void
    
    // Nine preset options from 30 sec to 30 min.
    private let durations: [TimeInterval] = [30, 60, 120, 180, 300, 600, 900, 1200, 1800]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Select Disable Duration")) {
                    Picker("Disable for", selection: $selectedDuration) {
                        ForEach(durations, id: \.self) { duration in
                            Text(durationText(for: duration)).tag(duration)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                }
            }
            .navigationTitle("Disable Reminder")
            .navigationBarItems(trailing: Button("Confirm") {
                disableAction()
            })
        }
    }
    
    private func durationText(for duration: TimeInterval) -> String {
        if duration < 60 {
            return "\(Int(duration)) sec"
        } else {
            let minutes = Int(duration) / 60
            return "\(minutes) min\(minutes > 1 ? "s" : "")"
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(BluetoothViewModel())
    }
}
