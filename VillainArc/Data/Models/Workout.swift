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
    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.workout)
    var exercises: [WorkoutExercise] = []
    
    init(title: String = "New Workout") {
        self.title = title
    }
    
    func addExercise(_ exercise: Exercise) {
        let workoutExercise = WorkoutExercise(from: exercise, workout: self)
        exercises.append(workoutExercise)
    }
    
    func removeExercise(_ exercise: WorkoutExercise) {
        exercises.removeAll { $0 == exercise }
    }
    
    // Testing
    init(title: String, notes: String = "", completed: Bool = false, endTime: Date? = nil) {
        self.title = title
        self.notes = notes
        self.completed = completed
        self.endTime = endTime
    }
}
