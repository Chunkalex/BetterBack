import SwiftUI

struct CalibrationView: View {
    @State private var calibrationStarted = false
    @State private var standCalibrationRecorded = false
    @State private var sitCalibrationRecorded = false
    @State private var calibrationMessage = "Follow these steps:\nFirst, press \"Start Calibration\"\nThen, record Stand and Sit postures"
    @EnvironmentObject var bleViewModel: BluetoothViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Title at the top.
                Text("Set up your new BetterBack")
                    .font(.title)
                                        .padding(.horizontal)
                                        .padding(.top, 5)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                
                // Dynamic calibration message.
                Text(calibrationMessage)
                    .multilineTextAlignment(.leading)
                                     .font(.system(size: 20))
                                     .padding(.horizontal)
                                     .padding(.top, 5)
                
                Spacer()
                
                // Button group for calibration actions.
                if !calibrationStarted {
                    Button("Start Calibration") {
                        startCalibration()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                } else {
                    // If calibration has started, show buttons for both stand and sit
                    if !standCalibrationRecorded {
                        Button("Record Stand Posture") {
                            recordStandPosture()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    
                    if !sitCalibrationRecorded {
                        Button("Record Sit Posture") {
                            recordSitPosture()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                
                Button("Restart Calibration") {
                    restartCalibration()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Calibration")
        }
    }
    
    // MARK: - Calibration Actions
    
    private func startCalibration() {
        calibrationStarted = true
        calibrationMessage = "Calibration started.\nPlease record Stand and Sit postures."
    }
    
    private func recordStandPosture() {
        let commandString = "a1"
        print("Sending: \(commandString)")
        if let data = commandString.data(using: .utf8) {
            bleViewModel.sendData(data)
        }
        standCalibrationRecorded = true
        calibrationMessage = "Stand posture recorded."
        checkIfCalibrationComplete()
    }
    
    private func recordSitPosture() {
        let commandString = "b1"
        print("Sending: \(commandString)")
        if let data = commandString.data(using: .utf8) {
            bleViewModel.sendData(data)
        }
        sitCalibrationRecorded = true
        calibrationMessage = "Sit posture recorded."
        checkIfCalibrationComplete()
    }
    
    private func checkIfCalibrationComplete() {
        if standCalibrationRecorded && sitCalibrationRecorded {
            calibrationMessage = "Both postures recorded.\nCalibrating..."
            // Wait 10 seconds before finalizing calibration.
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                calibrationMessage = "CALIBRATION FINISHED"
            }
        }
    }
    
    private func restartCalibration() {
        // Reset states.
        calibrationStarted = false
        standCalibrationRecorded = false
        sitCalibrationRecorded = false
        calibrationMessage = "Calibration restarted.\nPress \"Start Calibration\" to begin."
    }
}

struct CalibrationView_Previews: PreviewProvider {
    static var previews: some View {
        CalibrationView()
            .environmentObject(BluetoothViewModel())
    }
}
