import SwiftUI
import SwiftData

@MainActor
class DataContainer {
    var modelContainer: ModelContainer
    
    var context: ModelContext {
        modelContainer.mainContext
    }
    
    init(testingData: Bool = false) {
        let schema = Schema([
            Workout.self,
            WorkoutExercise.self,
            ExerciseSet.self,
            Exercise.self,
        ])

        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: testingData, allowsSave: true)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContainer.mainContext.autosaveEnabled = true
            
            if testingData {
                loadSampleData()
                syncExercises()
            } else {
                seedExercisesIfNeeded()
            }

            try context.save()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    private func loadSampleData() {
        for workout in Workout.sampleData {
            context.insert(workout)
        }
    }

    private func seedExercisesIfNeeded() {
        let catalogVersion = ExerciseDetails.allCases.count
        print("Catalog version: \(catalogVersion)")
        let storedVersion = UserDefaults.standard.integer(forKey: "exerciseCatalogVersion")
        print("Stored version: \(storedVersion)")

        if storedVersion != catalogVersion {
            syncExercises()
            UserDefaults.standard.set(catalogVersion, forKey: "exerciseCatalogVersion")
        }
    }

    private func syncExercises() {
        
        for exerciseDetail in ExerciseDetails.allCases {
            let name = exerciseDetail.rawValue
            let predicate = #Predicate<Exercise> {
                $0.name == name
            }
            let descriptor = FetchDescriptor(predicate: predicate)

            if (try? context.fetch(descriptor))?.isEmpty ?? true {
                context.insert(Exercise(from: exerciseDetail))
            }
        }
    }
}

private let sampleContainer = DataContainer(testingData: true)

extension View {
    func sampleDataConainer() -> some View {
        self
            .modelContainer(sampleContainer.modelContainer)
    }
}
