import SwiftUI
import SwiftData
import Firebase

@main
struct VillainArcApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [WeightEntry.self, User.self, Workout.self, WorkoutExercise.self, ExerciseSet.self])
    }
}
