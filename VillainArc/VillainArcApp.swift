import SwiftUI
import SwiftData
import Firebase
import CloudKit

@main
struct VillainArcApp: App {
    @AppStorage("iCloudEnabled") var iCloudEnabled = false
    
    init() {
        FirebaseApp.configure()
        checkICloudAvailability()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [WeightEntry.self, User.self, Workout.self, WorkoutExercise.self, ExerciseSet.self, HealthSteps.self, HealthActiveEnergy.self, HealthRestingEnergy.self, HealthWalkingRunningDistance.self])
    }
    
    func checkICloudAvailability() {
        CKContainer.default().accountStatus { status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    iCloudEnabled = true
                default:
                    iCloudEnabled = false
                }
            }
        }
    }
}
