import SwiftUI
import SwiftData

struct AddExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var exercises: [Exercise]
    
    @Bindable var workout: Workout
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            FilteredExerciseListView(exerciseName: searchText)
                .navigationTitle("Exercises")
                .navigationSubtitle(Text(" Selected"))
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .close) {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(role: .confirm) {
                            
                        }
                    }
                }
                .searchable(text: $searchText)
        }
    }
}

#Preview {
    AddExerciseView(workout: Workout.sampleData.first!)
        .sampleDataConainer()
}
