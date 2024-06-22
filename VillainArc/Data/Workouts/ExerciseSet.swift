import Foundation
import SwiftData

@Model
class ExerciseSet: Identifiable {
    var id: String = UUID().uuidString
    var reps: Int = 0
    var weight: Double = 0
    var order: Int = 0
    var restMinutes: Int = 0
    var restSeconds: Int = 0
    var exercise: WorkoutExercise?
    
    init(id: String, reps: Int, weight: Double, order: Int, restMinutes: Int, restSeconds: Int, exercise: WorkoutExercise) {
        self.id = id
        self.reps = reps
        self.weight = weight
        self.order = order
        self.restMinutes = restMinutes
        self.restSeconds = restSeconds
        self.exercise = exercise
    }
    init(id: String, order: Int, tempSet: TempSet, exercise: WorkoutExercise) {
        self.id = id
        self.reps = tempSet.reps
        self.weight = tempSet.weight
        self.order = order
        self.restMinutes = tempSet.restMinutes
        self.restSeconds = tempSet.restSeconds
        self.exercise = exercise
    }
    init(id: String, set: ExerciseSet, exercise: WorkoutExercise) {
        self.id = id
        self.reps = set.reps
        self.weight = set.weight
        self.order = set.order
        self.restMinutes = set.restMinutes
        self.restSeconds = set.restSeconds
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
