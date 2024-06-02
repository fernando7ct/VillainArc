import Foundation
import SwiftData

@Model
class ExerciseSet {
    var id: String
    var reps: Int
    var weight: Double
    var order: Int
    var exercise: WorkoutExercise
    
    init(id: String, reps: Int, weight: Double, order: Int, exercise: WorkoutExercise) {
        self.id = id
        self.reps = reps
        self.weight = weight
        self.order = order
        self.exercise = exercise
    }
}

struct TempSet: Identifiable {
    var id = UUID()
    var reps: Int
    var weight: Double
    var completed: Bool
    
    init(reps: Int, weight: Double, completed: Bool) {
        self.reps = reps
        self.weight = weight
        self.completed = completed
    }
    
    init(from set: ExerciseSet) {
        self.reps = set.reps
        self.weight = set.weight
        self.completed = false
    }
}
