import SwiftUI
import Combine
import UserNotifications

class TimerDisplayViewModel: ObservableObject {
    @Published var timeRemaining: TimeInterval = 0
    private var endDate: Date? = nil
    private var timerSubscription: AnyCancellable?
    private var hasRequestedAuthorization = false
    
    func startTimer(minutes: Int, seconds: Int) {
        let totalSeconds = TimeInterval(minutes * 60 + seconds)
        endDate = Date().addingTimeInterval(totalSeconds)
        
        updateTimeRemaining()
        
        timerSubscription?.cancel()
        
        NotificationManager.shared.removeAllNotifications()
        
        timerSubscription = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimeRemaining()
            }
        
        if !hasRequestedAuthorization {
            NotificationManager.shared.requestAuthorization()
            hasRequestedAuthorization = true
        }
        
        if totalSeconds > 10 {
            NotificationManager.shared.scheduleNotification(
                title: "Rest Time is Up",
                body: "Let's get back to your workout!",
                timeInterval: totalSeconds
            )
        } else {
            print("Not scheduling notification: rest time \(totalSeconds) is less than 10 seconds")
        }
    }
    
    func updateTimeRemaining() {
        guard let endDate = endDate else {
            timeRemaining = 0
            return
        }
        let currentTime = Date()
        timeRemaining = endDate.timeIntervalSince(currentTime)
        if timeRemaining <= 0 {
            timeRemaining = 0
            timerSubscription?.cancel()
            print("Timer finished")
        }
    }
    
    func formattedTime() -> String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}


struct TimerDisplayView: View {
    @ObservedObject var viewModel: TimerDisplayViewModel
    
    var body: some View {
        VStack {
            if viewModel.timeRemaining > 0 {
                Text(viewModel.formattedTime())
                    .font(.title)
                    .padding(.horizontal, 5)
                    .background {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(lineWidth: 2)
                    }
            }
        }
        .onAppear {
            viewModel.updateTimeRemaining()
        }
    }
}

#Preview {
    TimerDisplayView(viewModel: TimerDisplayViewModel())
}
