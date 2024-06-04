import SwiftUI
import ActivityKit

struct WorkoutAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var currentExerciseName: String
        var currentSetDetails: String
        var notes: String
        var timeRemaining: TimeInterval
        var allExercisesDone: Bool
        var totalTime: TimeInterval
    }
    var workoutTitle: String
}
