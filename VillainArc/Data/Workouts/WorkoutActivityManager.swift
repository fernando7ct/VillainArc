import SwiftUI
import ActivityKit

class WorkoutActivityManager {
    static let shared = WorkoutActivityManager()
    
    private var activity: Activity<WorkoutAttributes>?

    private init() {}

    func startLiveActivity(with exercises: [TempExercise], title: String, startTime: Date) {
        let data = currentActiveSet(from: exercises)
        let contentState = WorkoutAttributes.ContentState(
            exerciseName: currentActiveExercise(from: exercises),
            setNumber: data.0,
            setReps: data.1,
            setWeight: data.2,
            date: startTime,
            isEmpty: exercises.isEmpty,
            workoutTitle: title,
            endDate: nil
        )
        let attributes = WorkoutAttributes()
        let activityContent = ActivityContent(state: contentState, staleDate: nil)
        do {
            activity = try Activity<WorkoutAttributes>.request(attributes: attributes, content: activityContent)
        } catch {
            print("Failed to start live activity: \(error)")
        }
    }

    func updateLiveActivity(with exercises: [TempExercise], title: String, startTime: Date, timer: TimerDisplayViewModel) {
        let data = currentActiveSet(from: exercises)
        var endDate: Date? = nil
        if let end = timer.restEndDate {
            endDate = end
        }
        let updatedContentState = WorkoutAttributes.ContentState(
            exerciseName: currentActiveExercise(from: exercises),
            setNumber: data.0,
            setReps: data.1,
            setWeight: data.2,
            date: startTime,
            isEmpty: exercises.isEmpty,
            workoutTitle: title,
            endDate: endDate
        )
        let updatedContent = ActivityContent(state: updatedContentState, staleDate: nil)
        Task {
            await activity?.update(updatedContent)
        }
    }

    func endLiveActivity() {
        Task {
            await activity?.end(dismissalPolicy: .immediate)
        }
    }

    private func currentActiveExercise(from exercises: [TempExercise]) -> String {
        for exercise in exercises {
            for set in exercise.sets where !set.completed {
                return exercise.name
            }
        }
        return ""
    }

    private func currentActiveSet(from exercises: [TempExercise]) -> (Int, Int, Double) {
        for exercise in exercises {
            for (index, set) in exercise.sets.enumerated() where !set.completed {
                return ((index + 1), (set.reps), (set.weight))
            }
        }
        return (0, 0, 0)
    }
}
