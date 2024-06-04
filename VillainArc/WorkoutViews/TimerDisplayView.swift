import SwiftUI
import Combine
import UserNotifications
import ActivityKit

class TimerDisplayViewModel: ObservableObject {
    @Published var restTimeRemaining: TimeInterval = 0
    @Published var totalTime: TimeInterval = 0
    
    private var restEndDate: Date? = nil
    private var totalStartDate: Date? = nil
    
    private var restTimerSubscription: AnyCancellable?
    private var totalTimerSubscription: AnyCancellable?
    
    private var hasRequestedAuthorization = false
    var activity: Activity<WorkoutAttributes>?
    
    func startWorkoutTimer() {
        totalStartDate = Date()
        updateTotalTime()
        
        totalTimerSubscription?.cancel()
        totalTimerSubscription = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTotalTime()
                self?.updateLiveActivity()
            }
    }
    
    func startRestTimer(workoutTitle: String, exerciseName: String, currentSetDetails: String, notes: String, allExercisesDone: Bool, minutes: Int, seconds: Int) {
        let totalSeconds = TimeInterval(minutes * 60 + seconds)
        restEndDate = Date().addingTimeInterval(totalSeconds)
        
        updateRestTimeRemaining()
        
        restTimerSubscription?.cancel()
        
        NotificationManager.shared.removeAllNotifications()
        
        restTimerSubscription = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateRestTimeRemaining()
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
            allExercisesDone: allExercisesDone,
            totalTime: totalTime
        )
        let activityAttributes = WorkoutAttributes(workoutTitle: workoutTitle)
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
        NotificationManager.shared.removeAllNotifications()
        if let activity = activity {
            await activity.end(ActivityContent(state: activity.content.state, staleDate: Date()), dismissalPolicy: .immediate)
            self.activity = nil
        }
    }
    
    private func updateTotalTime() {
        guard let totalStartDate = totalStartDate else {
            totalTime = 0
            return
        }
        totalTime = Date().timeIntervalSince(totalStartDate)
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
    
    func updateLiveActivity() {
        guard let activity = activity else { return }
        
        let state = WorkoutAttributes.ContentState(
            currentExerciseName: activity.content.state.currentExerciseName,
            currentSetDetails: activity.content.state.currentSetDetails,
            notes: activity.content.state.notes,
            timeRemaining: restTimeRemaining,
            allExercisesDone: activity.content.state.allExercisesDone,
            totalTime: totalTime // Add this
        )
        
        Task {
            await activity.update(ActivityContent(state: state, staleDate: Date().addingTimeInterval(60 * 60)))
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
