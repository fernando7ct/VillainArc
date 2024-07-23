import SwiftUI
import SwiftData

struct ExerciseHistoryView: View {
    @Binding var exerciseName: String
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var exercises: [WorkoutExercise] = []
    var onSelectHistory: (([TempSet], String?, String?) -> Void)?
    
    private func fetchExerciseHistory() {
        let fetchDescriptor = FetchDescriptor<WorkoutExercise>(
            predicate: #Predicate { $0.name == exerciseName && $0.workout?.template != true },
            sortBy: [SortDescriptor(\WorkoutExercise.date, order: .reverse)]
        )
        exercises = try! context.fetch(fetchDescriptor)
    }
    private func convertToTempSets(sets: [ExerciseSet]) -> [TempSet] {
        sets.sorted(by: { $0.order < $1.order }).map { set in
            TempSet(from: set)
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
                        ForEach(exercises) { exercise in
                            Section(content: {
                                ForEach(exercise.sets.sorted(by: { $0.order < $1.order })) { set in
                                    HStack {
                                        Text("Set: \(set.order + 1)")
                                        Spacer()
                                        Text("Reps: \(set.reps)")
                                        Spacer()
                                        Text("Weight: \(formattedDouble(set.weight)) lbs")
                                    }
                                    .listRowSeparator(.hidden)
                                }
                            }, header: {
                                HStack {
                                    Text("\(exercise.date.formatted(.dateTime.month().day().year()))")
                                        .foregroundStyle(Color.primary)
                                    Spacer()
                                    if !exercise.notes.isEmpty || !exercise.repRange.isEmpty {
                                        Menu {
                                            Button(action: {
                                                let tempSets = convertToTempSets(sets: exercise.sets)
                                                onSelectHistory?(tempSets, nil, nil)
                                                dismiss()
                                            }, label: {
                                                Text("Copy Sets Only")
                                            })
                                            if !exercise.notes.isEmpty {
                                                Button(action: {
                                                    let tempSets = convertToTempSets(sets: exercise.sets)
                                                    onSelectHistory?(tempSets, exercise.notes, nil)
                                                    dismiss()
                                                }, label: {
                                                    Text("Copy Sets & Notes")
                                                })
                                            }
                                            if !exercise.repRange.isEmpty {
                                                Button(action: {
                                                    let tempSets = convertToTempSets(sets: exercise.sets)
                                                    onSelectHistory?(tempSets, nil, exercise.repRange)
                                                    dismiss()
                                                }, label: {
                                                    Text("Copy Sets & Rep Range")
                                                })
                                            }
                                            if !exercise.notes.isEmpty && !exercise.repRange.isEmpty {
                                                Button(action: {
                                                    let tempSets = convertToTempSets(sets: exercise.sets)
                                                    onSelectHistory?(tempSets, exercise.notes, exercise.repRange)
                                                    dismiss()
                                                }, label: {
                                                    Text("Copy All")
                                                })
                                            }
                                        } label: {
                                            Text("Copy Sets")
                                                .font(.subheadline)
                                                .foregroundStyle(.blue)
                                        }
                                        .textCase(.none)
                                    } else {
                                        Button(action: {
                                            let tempSets = convertToTempSets(sets: exercise.sets)
                                            onSelectHistory?(tempSets, nil, nil)
                                            dismiss()
                                        }, label: {
                                            Text("Copy Sets")
                                                .font(.subheadline)
                                                .foregroundStyle(.blue)
                                        })
                                        .textCase(.none)
                                    }
                                }
                                .fontWeight(.semibold)
                            }, footer: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 0) {
                                        if !exercise.repRange.isEmpty {
                                            Text("Rep Range: \(exercise.repRange)")
                                        }
                                        if !exercise.notes.isEmpty {
                                            Text("Notes: \(exercise.notes)")
                                        }
                                    }
                                    Spacer()
                                }
                            })
                            .listRowBackground(BlurView())
                        }
                    }
                }
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                .scrollContentBackground(.hidden)
                .onAppear(perform: fetchExerciseHistory)
                .navigationTitle(exerciseName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .symbolRenderingMode(.hierarchical)
                                .fontWeight(.semibold)
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}
