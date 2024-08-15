import SwiftUI
import MapKit

struct RunView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var runLM = RunLocationManager.shared
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var countDownValue = 3
    @State private var sheetDetent: PresentationDetent = .height((UIScreen.main.bounds.height * 2) / 3)
    @State private var showMap = false
    @State private var startTime = Date()
    
    var body: some View {
        if runLM.locationEnabled {
            if countDownValue > 0 {
                CountDownView
            } else {
                VStack {
                    Map(position: $cameraPosition) {
                        UserAnnotation()
                        if !runLM.locations.isEmpty {
                            MapPolyline(coordinates: runLM.locations.map { $0.coordinate })
                                .stroke(Color.blue, lineWidth: 4)
                        }
                    }
                    .mapStyle(.standard(elevation: .realistic))
                    .frame(height: UIScreen.main.bounds.height / 5)
                    .padding(.bottom)
                    
                    HStack {
                        VStack(alignment: .center) {
                            Text("Time")
                                .foregroundStyle(.secondary)
                                .font(.title2)
                            Text(startTime, style: .timer)
                                .font(.largeTitle)
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
                            Text("\(formattedPace(runLM.calculateAveragePace()))")
                                .font(.largeTitle)
                        }
                        .hSpacing(.center)
                        .fontWeight(.semibold)
                    }
                    .padding(.vertical)
                }
                .vSpacing(.top)
                .safeAreaInset(edge: .top) {
                    HStack {
                        Button {
                            runLM.stopTracking()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .symbolRenderingMode(.hierarchical)
                                .fontWeight(.semibold)
                                .font(.title)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .hSpacing(.trailing)
                    .padding()
                }
                .background(BackgroundView())
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
                countDownValue -= 1
                startTime = Date()
            } else {
                timer.invalidate()
                runLM.startUpdatingLocation()
            }
        }
    }
    
    private func formattedPace(_ pace: Double) -> String {
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var CountDownView: some View {
        VStack {
            Text(countDownValue, format: .number)
                .font(.system(size: 100))
                .fontWeight(.bold)
                .offset(y: -40)
        }
        .vSpacing(.center)
        .safeAreaInset(edge: .top) {
            HStack {
                Button {
                    runLM.stopTracking()
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
}
