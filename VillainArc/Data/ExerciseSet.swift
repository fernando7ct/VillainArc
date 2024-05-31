import Foundation
import SwiftData

@Model
class ExerciseSet {
    var id: String
    var reps: Int
    var weight: Double
    var exercise: WorkoutExercise
    
    init(id: String, reps: Int, weight: Double, exercise: WorkoutExercise) {
        self.id = id
        self.reps = reps
        self.weight = weight
        self.exercise = exercise
    }
}
