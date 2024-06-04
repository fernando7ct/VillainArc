import SwiftUI
import Combine
import UserNotifications
import ActivityKit

class TimerDisplayViewModel: ObservableObject {
    @Published var timeRemaining: TimeInterval = 0
    private var endDate: Date? = nil
    private var timerSubscription: AnyCancellable?
    private var hasRequestedAuthorization = false
    var activity: Activity<WorkoutAttributes>?
    
    func startTimer(workoutTitle: String, exerciseName: String, currentSetDetails: String, notes: String, allExercisesDone: Bool, minutes: Int, seconds: Int) {
        let totalSeconds = TimeInterval(minutes * 60 + seconds)
        endDate = Date().addingTimeInterval(totalSeconds)
        
        updateTimeRemaining()
        
        timerSubscription?.cancel()
        
        NotificationManager.shared.removeAllNotifications()
        
        timerSubscription = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimeRemaining()
                self?.updateLiveActivity()
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
        
        let initialContentState = WorkoutAttributes.ContentState(
            currentExerciseName: exerciseName,
            currentSetDetails: currentSetDetails,
            notes: notes,
            timeRemaining: totalSeconds,
            allExercisesDone: allExercisesDone
        )
        let activityAttributes = WorkoutAttributes(workoutTitle: workoutTitle, totalTime: totalSeconds)
        let staleDate = Date().addingTimeInterval(60 * 60) // Example: 1 hour in the future
        
        if let activity = activity {
            // Update existing activity
            Task {
                await activity.update(ActivityContent(state: initialContentState, staleDate: staleDate))
            }
        } else {
            // Start a new activity
            Task {
                do {
                    activity = try Activity<WorkoutAttributes>.request(
                        attributes: activityAttributes,
                        content: ActivityContent(state: initialContentState, staleDate: staleDate),
                        pushType: nil)
                    print("Live Activity started: \(activity?.id ?? "unknown")")
                } catch {
                    print("Failed to start Live Activity: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func endActivity() async {
        if let activity = activity {
            await activity.end(ActivityContent(state: activity.content.state, staleDate: Date()), dismissalPolicy: .immediate)
            self.activity = nil
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
    
    func updateLiveActivity() {
        guard let activity = activity else { return }
        
        let state = WorkoutAttributes.ContentState(
            currentExerciseName: activity.content.state.currentExerciseName,
            currentSetDetails: activity.content.state.currentSetDetails,
            notes: activity.content.state.notes,
            timeRemaining: timeRemaining,
            allExercisesDone: activity.content.state.allExercisesDone
        )
        
        Task {
            await activity.update(ActivityContent(state: state, staleDate: Date().addingTimeInterval(60 * 60)))
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
