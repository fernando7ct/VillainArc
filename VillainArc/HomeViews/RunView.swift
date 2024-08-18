import SwiftUI
import MapKit

struct RunView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @StateObject var runLM = RunLocationManager()
    @State private var countDownValue = 3
    @State private var startTime = Date()
    @State private var displayTime = Date()
    @State private var isPaused = false
    @State private var pauseTime = Date()

    var body: some View {
        if runLM.locationEnabled {
            if countDownValue > 0 {
                CountDownView
            } else {
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .center) {
                            Text("Time")
                                .foregroundStyle(.secondary)
                                .font(.title2)
                            if !isPaused {
                                Text(displayTime, style: .timer)
                                    .font(.largeTitle)
                            } else {
                                Text("\(totalWorkoutTime(startTime: startTime, endTime: pauseTime))")
                                    .font(.largeTitle)
                                    .foregroundStyle(.yellow)
                            }
                        }
                        .hSpacing(.center)
                        .fontWeight(.semibold)
                        
                        VStack(alignment: .center) {
                            Text("Distance")
                                .foregroundStyle(.secondary)
                                .font(.title2)
                            Text("\(runLM.distanceTraveled, specifier: "%.2f") mi")
                                .font(.largeTitle)
                        }
                        .hSpacing(.center)
                        .fontWeight(.semibold)
                    }
                    .hSpacing(.center)
                    .padding(.bottom)
                    
                    HStack {
                        VStack(alignment: .center) {
                            Text("Current Pace")
                                .foregroundStyle(.secondary)
                                .font(.title2)
                            Text("\(formattedPace(runLM.currentPace))")
                                .font(.largeTitle)
                        }
                        .hSpacing(.center)
                        .fontWeight(.semibold)
                        
                        VStack(alignment: .center) {
                            Text("Average Pace")
                                .foregroundStyle(.secondary)
                                .font(.title2)
                            Text("\(formattedPace(runLM.averagePace))")
                                .font(.largeTitle)
                        }
                        .hSpacing(.center)
                        .fontWeight(.semibold)
                    }
                    .padding(.vertical)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(0..<runLM.milePaces.count, id: \.self) { index in
                            let mileData = runLM.milePaces[index]
                            Text("Mile \(mileData.mile): \(formattedPace(mileData.pace)) min/mi")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                }
                .vSpacing(.top)
                .background(BackgroundView())
                .onAppear {
                    runLM.startUpdatingLocation()
                }
                .safeAreaInset(edge: .top) {
                    HStack {
                        Menu {
                            Button {
                                runLM.finishRun()
                                if runLM.distanceTraveled >= 0.01 {
                                    saveRun()
                                }
                                dismiss()
                            } label: {
                                Label("Save Run", systemImage: "checkmark.circle")
                            }
                            Button {
                                if isPaused {
                                    resumeRun()
                                } else {
                                    pauseRun()
                                }
                            } label: {
                                Label(isPaused ? "Resume Run" : "Pause Run", systemImage: isPaused ? "play.fill" : "pause.fill")
                            }
                            Button(role: .destructive) {
                                runLM.stopTracking()
                                dismiss()
                            } label: {
                                Label("Cancel Run", systemImage: "xmark")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .fontWeight(.semibold)
                                .font(.title2)
                                .padding()
                                .background(.ultraThickMaterial, in: .circle)
                        }
                    }
                    .hSpacing(.trailing)
                    .padding()
                }
            }
        } else {
            Button {
                dismiss()
            } label: {
                Text("Dismiss")
            }
        }
    }
    private func startCountDown() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countDownValue > 0 {
                displayTime = Date()
                startTime = Date()
                countDownValue -= 1
            } else {
                timer.invalidate()
                runLM.startRun()
            }
        }
    }
    private func formattedPace(_ pace: Double) -> String {
        guard pace.isFinite && !pace.isNaN else {
            return "N/A"
        }
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%d:%02d", minutes, seconds)
    }
    private func saveRun() {
        let mileSplits = runLM.milePaces.map { [$0.mile, $0.pace] }
        DataManager.shared.saveRun(distance: runLM.distanceTraveled, startTime: startTime, endTime: Date(), averagePace: runLM.averagePace, mileSplits: mileSplits, context: context)
    }
    private func pauseRun() {
        isPaused = true
        pauseTime = Date()
        runLM.stopTracking()
    }
    private func resumeRun() {
        isPaused = false
        let pauseDuration = Date().timeIntervalSince(pauseTime)
        displayTime = displayTime.addingTimeInterval(pauseDuration)
        runLM.startUpdatingLocation()
    }
    var CountDownView: some View {
        VStack {
            Text(countDownValue, format: .number)
                .font(.system(size: 100))
                .fontWeight(.bold)
                .offset(y: -60)
        }
        .vSpacing(.center)
        .safeAreaInset(edge: .top) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .fontWeight(.semibold)
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
            }
            .hSpacing(.trailing)
            .padding()
        }
        .onAppear {
            startCountDown()
        }
        .background(BackgroundView())
    }
}

#Preview {
    RunView()
        .tint(.primary)
}
