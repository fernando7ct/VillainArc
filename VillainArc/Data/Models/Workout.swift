import Foundation
import SwiftData

@Model
class Workout {
    var id: UUID = UUID()
    var title: String = ""
    var notes: String = ""
    var completed: Bool = false
    var startTime: Date = Date.now
    var endTime: Date? = nil
    @Relationship(deleteRule: .cascade)
    var exercises: [WorkoutExercise] = []
    
    init(title: String = "New Workout") {
        self.title = title
    }
    
    init(from workout: Workout) {
        title = workout.title
        notes = workout.notes
        for exercise in workout.exercises {
            exercises.append(WorkoutExercise(from: exercise, workout: self))
        }
    }
    
    // Testing
    init(title: String, notes: String = "", completed: Bool = false, endTime: Date? = nil) {
        self.title = title
        self.notes = notes
        self.completed = completed
        self.endTime = endTime
    }
}
