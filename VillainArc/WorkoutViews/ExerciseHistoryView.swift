import SwiftUI
import SwiftData

struct ExerciseHistoryView: View {
    @Binding var exerciseName: String
    @Environment(\.modelContext) private var context
    @State private var exercises: [WorkoutExercise] = []
    
    private func fetchExerciseHistory() {
        let fetchDescriptor = FetchDescriptor<WorkoutExercise>(
            predicate: #Predicate { $0.name == exerciseName },
            sortBy: [SortDescriptor(\WorkoutExercise.date, order: .reverse)]
        )
        do {
            exercises = try context.fetch(fetchDescriptor)
            exercises = exercises.filter { $0.workout.template != true }
        } catch {
            
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
                                }
                            }, header: {
                                Text("\(exercise.date.formatted(.dateTime.month().day().year()))")
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
