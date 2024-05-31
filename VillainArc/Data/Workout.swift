import Foundation
import SwiftData

@Model
class Workout {
    var id: String
    var title: String
    var startTime: Date
    var endTime: Date
    var notes: String
    var exercises: [WorkoutExercise]
    
    init(id: String, title: String, startTime: Date, endTime: Date, notes: String, exercises: [WorkoutExercise]) {
        self.id = id
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.notes = notes
        self.exercises = exercises
    }
}
