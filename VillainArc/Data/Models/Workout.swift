import Foundation
import SwiftData

@Model
class Workout {
    var id: UUID
    var title: String
    var notes: String
    var completed: Bool
    var startTime: Date
    var endTime: Date?
    @Relationship(deleteRule: .cascade)
    var exercises: [WorkoutExercise]
    
    init(id: UUID = UUID(), title: String, notes: String = "", completed: Bool = false, startTime: Date = .now, endTime: Date? = nil, exercises: [WorkoutExercise] = []) {
        self.id = id
        self.title = title
        self.notes = notes
        self.completed = completed
        self.startTime = startTime
        self.endTime = endTime
        self.exercises = exercises
    }
}

extension Workout {
    static var sampleData: [Workout] {
        let now = Date()
        func end(after minutes: Int) -> Date {
            Calendar.current.date(byAdding: .minute, value: minutes, to: now) ?? now
        }
        
        let chest = Workout(
            title: "Chest Day",
            notes: "Testing sample",
            completed: true,
            startTime: now,
            endTime: end(after: 60))
        chest.exercises = WorkoutExercise.chestDay(for: chest)
        
        let back = Workout(
            title: "Back Day",
            notes: "Testing sample",
            completed: true,
            startTime: now,
            endTime: end(after: 65))
        back.exercises = WorkoutExercise.backDay(for: back)
        
        let shoulder = Workout(
            title: "Shoulder Day",
            notes: "Testing sample",
            completed: true,
            startTime: now,
            endTime: end(after: 50))
        shoulder.exercises = WorkoutExercise.shoulderDay(for: shoulder)
        
        let arm = Workout(
            title: "Arm Day",
            notes: "Testing sample",
            completed: true,
            startTime: now,
            endTime: end(after: 45))
        arm.exercises = WorkoutExercise.armDay(for: arm)
        
        let leg = Workout(
            title: "Leg Day",
            notes: "Testing sample",
            completed: true,
            startTime: now,
            endTime: end(after: 1000))
        leg.exercises = WorkoutExercise.legDay(for: leg)
        
        return [chest, back, shoulder, arm, leg]
    }
}
