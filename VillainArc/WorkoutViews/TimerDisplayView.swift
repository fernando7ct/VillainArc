import SwiftUI
import Combine
import UserNotifications

class TimerDisplayViewModel: ObservableObject {
    @Published var restTimeRemaining: TimeInterval = 0
    
    private var restEndDate: Date? = nil
    
    private var restTimerSubscription: AnyCancellable?
    
    private var hasRequestedAuthorization = false
    
    func startRestTimer(minutes: Int, seconds: Int) {
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
    func updateRestTimeRemaining() {
        guard let restEndDate = restEndDate else {
            restTimeRemaining = 0
            return
        }
        let currentTime = Date()
        restTimeRemaining = restEndDate.timeIntervalSince(currentTime)
        if restTimeRemaining <= 0 {
            restTimeRemaining = 0
            restTimerSubscription?.cancel()
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
            if viewModel.restTimeRemaining > 0 {
                Text(viewModel.formattedTime(viewModel.restTimeRemaining))
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
