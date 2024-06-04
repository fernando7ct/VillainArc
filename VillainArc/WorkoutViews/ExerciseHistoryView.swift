import SwiftUI
import SwiftData

struct ExerciseHistoryView: View {
    @Binding var exerciseName: String
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var exercises: [WorkoutExercise] = []
    var onSelectHistory: (([TempSet]) -> Void)?
    
    private func fetchExerciseHistory() {
        let fetchDescriptor = FetchDescriptor<WorkoutExercise>(
            predicate: #Predicate { $0.name == exerciseName },
            sortBy: [SortDescriptor(\WorkoutExercise.date, order: .reverse)]
        )
        do {
            exercises = try context.fetch(fetchDescriptor)
            exercises = exercises.filter { $0.workout.template != true }
        } catch {
            // Handle error if needed
        }
    }
    
    private func convertToTempSets(sets: [ExerciseSet]) -> [TempSet] {
        sets.sorted(by: { $0.order < $1.order }).map { set in
            TempSet(reps: set.reps, weight: set.weight, restMinutes: set.restMinutes, restSeconds: set.restSeconds, completed: false)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView()
                List {
                    if exercises.isEmpty {
                        Text("No exercise history.")
                            .listRowBackground(BlurView())
                    } else {
                        ForEach(exercises, id: \.self) { exercise in
                            Section(content: {
                                ForEach(exercise.sets.sorted(by: { $0.order < $1.order }), id: \.self) { set in
                                    HStack {
                                        Text("Set: \(set.order + 1)")
                                        Spacer()
                                        Text("Reps: \(set.reps)")
                                        Spacer()
                                        Text("Weight: \(formattedWeight(set.weight)) lbs")
                                    }
                                    .listRowSeparator(.hidden)
                                }
                            }, header: {
                                HStack {
                                    Text("\(exercise.date.formatted(.dateTime.month().day().year()))")
                                        .foregroundStyle(Color.primary)
                                    Spacer()
                                    Button(action: {
                                        let tempSets = convertToTempSets(sets: exercise.sets)
                                        onSelectHistory?(tempSets)
                                        dismiss()
                                    }, label: {
                                        Text("Use Sets")
                                            .font(.subheadline)
                                            .foregroundStyle(.blue)
                                    })
                                }
                                .fontWeight(.semibold)
                            })
                            .listRowBackground(BlurView())
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .onAppear(perform: fetchExerciseHistory)
                .navigationTitle(exerciseName)
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
