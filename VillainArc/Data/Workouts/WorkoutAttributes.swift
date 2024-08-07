import SwiftUI
import ActivityKit

struct WorkoutAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var exerciseName: String
        var setNumber: Int
        var setReps: Int
        var setWeight: Double
        var date: Date
        var isEmpty: Bool
        var workoutTitle: String
        var endDate: Date?
    }
}
