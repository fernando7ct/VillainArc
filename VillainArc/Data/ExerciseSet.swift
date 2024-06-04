import Foundation
import SwiftData

@Model
class ExerciseSet {
    var id: String
    var reps: Int
    var weight: Double
    var order: Int
    var restMinutes: Int
    var restSeconds: Int
    var exercise: WorkoutExercise
    
    init(id: String, reps: Int, weight: Double, order: Int, restMinutes: Int, restSeconds: Int, exercise: WorkoutExercise) {
        self.id = id
        self.reps = reps
        self.weight = weight
        self.order = order
        self.restMinutes = restMinutes
        self.restSeconds = restSeconds
        self.exercise = exercise
    }
}

struct TempSet: Identifiable {
    var id = UUID()
    var reps: Int
    var weight: Double
    var restMinutes: Int
    var restSeconds: Int
    var completed: Bool
    
    init(reps: Int, weight: Double, restMinutes: Int, restSeconds: Int, completed: Bool) {
        self.reps = reps
        self.weight = weight
        self.restMinutes = restMinutes
        self.restSeconds = restSeconds
        self.completed = completed
    }
    
    init(from set: ExerciseSet) {
        self.reps = set.reps
        self.weight = set.weight
        self.restMinutes = set.restMinutes
        self.restSeconds = set.restSeconds
        self.completed = false
    }
}
