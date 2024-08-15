import SwiftUI
import Combine
import UserNotifications

class TimerDisplayViewModel: ObservableObject {
    
    @Published var restEndDate: Date? = nil
    
    private var restTimerSubscription: AnyCancellable?
    
    private var hasRequestedAuthorization = false
    
    @MainActor func startRestTimer(minutes: Int, seconds: Int) {
        let totalSeconds = TimeInterval(minutes * 60 + seconds)
        restEndDate = Date().addingTimeInterval(totalSeconds)
        
        updateRestTimeRemaining()
        
        restTimerSubscription?.cancel()
        
        NotificationManager.shared.removeAllNotifications()
        restTimerSubscription = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateRestTimeRemaining()
            }
        
        if !hasRequestedAuthorization {
            NotificationManager.shared.requestAuthorization()
            hasRequestedAuthorization = true
        }
        
        if totalSeconds > 10 {
            NotificationManager.shared.scheduleNotification(
                title: "Villain Arc",
                body: "Rest Time is Up",
                timeInterval: totalSeconds
            )
        } else {
            print("Not scheduling notification: rest time \(totalSeconds) is less than 10 seconds")
        }
    }
    func endActivity() {
        NotificationManager.shared.removeAllNotifications()
    }
    @MainActor func updateRestTimeRemaining() {
        guard let endDate = restEndDate else {
            
            return
        }
        let currentTime = Date()
        let restTimeRemaining = endDate.timeIntervalSince(currentTime)
        if restTimeRemaining <= 0 {
            restTimerSubscription?.cancel()
            restEndDate = nil
            print("Rest timer finished")
        }
    }
    func formattedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct TimerDisplayView: View {
    @ObservedObject var viewModel: TimerDisplayViewModel
    
    var body: some View {
        VStack {
            if let endDate = viewModel.restEndDate {
                Text(endDate, style: .timer)
                    .font(.title)
                    .padding(.horizontal, 5)
                    .background {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(lineWidth: 2)
                    }
            } else {
                Text("0:00")
                    .font(.title)
                    .padding(.horizontal, 5)
                    .background {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(lineWidth: 2)
                    }
            }
        }
        .onAppear {
            viewModel.updateRestTimeRemaining()
        }
    }
}

#Preview {
    TimerDisplayView(viewModel: TimerDisplayViewModel())
}
