import SwiftUI
import Combine

class TimerDisplayViewModel: ObservableObject {
    
    @Published var restEndDate: Date? = nil
    
    private var restTimerSubscription: AnyCancellable?
    
    @MainActor func startRestTimer(minutes: Int, seconds: Int) {
        let totalSeconds = TimeInterval(minutes * 60 + seconds)
        guard totalSeconds > 0 else { return }
        restEndDate = Date().addingTimeInterval(totalSeconds)
        
        updateRestTimeRemaining()
        
        restTimerSubscription?.cancel()
        
        restTimerSubscription = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateRestTimeRemaining()
            }
        
        if NotificationManager.shared.notificationsAllowed {
            NotificationManager.shared.removeAllNotifications()
            NotificationManager.shared.scheduleNotification(title: "Villain Arc", body: "Rest Time is Up", timeInterval: totalSeconds)
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
