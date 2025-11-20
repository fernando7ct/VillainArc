import SwiftUI
import SwiftData

struct FilteredExerciseListView: View {
    @Query private var exercises: [Exercise]
    
    init(exerciseName: String = "") {
        let predicate = #Predicate<Exercise> { exercise in
            exerciseName.isEmpty || exercise.name.localizedStandardContains(exerciseName)
        }
        
        _exercises = Query(filter: predicate, sort: \.name)
    }
    
    var body: some View {
        List {
            ForEach(exercises) { exercise in
                Text(exercise.name)
            }
        }
    }
}

#Preview {
    AddExerciseView(workout: Workout.sampleData.first!)
        .sampleDataConainer()
}
