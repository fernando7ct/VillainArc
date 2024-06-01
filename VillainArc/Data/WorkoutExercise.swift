import Foundation
import SwiftData

@Model
class WorkoutExercise {
    var id: String
    var name: String
    var category: String
    var notes: String
    var date: Date
    var order: Int
    var workout: Workout
    var sets: [ExerciseSet]
    
    init(id: String, name: String, category: String, notes: String, date: Date, order: Int, workout: Workout, sets: [ExerciseSet]) {
        self.id = id
        self.name = name
        self.category = category
        self.notes = notes
        self.date = date
        self.order = order
        self.workout = workout
        self.sets = sets
    }
}
