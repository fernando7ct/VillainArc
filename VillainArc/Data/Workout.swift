import Foundation
import SwiftData

@Model
class Workout: Identifiable {
    var id: String
    var title: String
    var startTime: Date
    var endTime: Date
    var notes: String
    var template: Bool
    var exercises: [WorkoutExercise]
    
    init(id: String, title: String, startTime: Date, endTime: Date, notes: String, template: Bool, exercises: [WorkoutExercise]) {
        self.id = id
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        self.template = template
        self.exercises = exercises
    }
}
