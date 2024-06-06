import SwiftUI
import SwiftData
import Firebase
import CloudKit

@main
struct VillainArcApp: App {
    @AppStorage("isICloudEnabled") var isICloudEnabled: Bool = false
    
    init() {
        FirebaseApp.configure()
        checkICloudAvailability()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [WeightEntry.self, User.self, Workout.self, WorkoutExercise.self, ExerciseSet.self])
    }
    
    func checkICloudAvailability() {
        CKContainer.default().accountStatus { status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    isICloudEnabled = true
                    print("iCloud Enabled")
                default:
                    isICloudEnabled = false
                    print("iCloud Disabled")
                }
            }
        }
    }
}
