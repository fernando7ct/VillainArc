import SwiftUI
import SwiftData

struct AddExerciseView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var exercises: [Exercise]
    
    @Bindable var workout: Workout
    @State private var searchText = ""
    @State private var selectedExercises: [Exercise] = []
    @State private var showCancelConfirmation = false
    
    var body: some View {
        NavigationStack {
            FilteredExerciseListView(exerciseName: searchText, selectedExercises: $selectedExercises)
                .navigationTitle("Exercises")
                .navigationSubtitle(Text("\(selectedExercises.count) Selected"))
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .close) {
                            if selectedExercises.isEmpty {
                                dismiss()
                            } else {
                                showCancelConfirmation = true
                            }
                        }
                        .confirmationDialog("Discard selected exercises?", isPresented: $showCancelConfirmation) {
                            Button("Cancel") {
                                showCancelConfirmation = false
                            }
                            Button("Discard Selections", role: .destructive) {
                                selectedExercises.removeAll()
                                dismiss()
                            }
                        } message: {
                            Text("If you leave now, the selected exercises will not be added to your workout.")
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(role: .confirm) {
                            if selectedExercises.isEmpty {
                                dismiss()
                            } else {
                                addSelectedExercises()
                            }
                        }
                    }
                }
                .searchable(text: $searchText)
        }
    }
    
    private func addSelectedExercises() {
        for exercise in selectedExercises {
            workout.exercises.append(WorkoutExercise(from: exercise, workout: workout))
            exercise.lastUsed = .now
            try? context.save()
        }
        dismiss()
    }
}

#Preview {
    AddExerciseView(workout: Workout.sampleData.first!)
        .sampleDataConainer()
}
