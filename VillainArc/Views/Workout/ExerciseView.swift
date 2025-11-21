import SwiftUI
import SwiftData

struct ExerciseView: View {
    @Query private var exercises: [WorkoutExercise]
    @Environment(\.modelContext) private var context
    @Bindable var exercise: WorkoutExercise
    @State private var isNotesExpanded = false
    
    init(exercise: WorkoutExercise) {
        self.exercise = exercise
        
        let name = exercise.name
        let predicate = #Predicate<WorkoutExercise> { exercise in
            exercise.name == name && exercise.workout?.completed == true
        }
        _exercises = Query(filter: predicate, sort: \.date, order: .reverse)
    }
    
    private var previousSets: [ExerciseSet] {
        exercises.first?.sets ?? []
    }
    
    private func previousSetDisplay(for index: Int) -> String {
        guard index < previousSets.count else { return "-" }
        let set = previousSets[index]
        return "\(set.reps)x\(Int(set.weight))"
    }
    
    var body: some View {
        GeometryReader { geometry in
            List {
                headerView
                
                if !exercise.sets.isEmpty {
                    Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                        GridRow {
                            Text("Set")
                            Text("Reps")
                                .gridColumnAlignment(.leading)
                            Text("Weight")
                                .gridColumnAlignment(.leading)
                            Text("Previous")
                            Text(" ")
                        }
                        .font(.title3)
                        .bold()
                        
                        ForEach(exercise.sets) { set in
                            GridRow {
                                if let index = exercise.sets.firstIndex(where: { $0.id == set.id }) {
                                    ExerciseSetRowView(set: set, exercise: exercise, setNumber: index + 1, previousSetDisplay: previousSetDisplay(for: index), fieldWidth: geometry.size.width / 5)
                                }
                            }
                            .font(.title3)
                            .fontWeight(.semibold)
                        }
                    }
                    .listRowBackground(Color.clear)
                }
                
                Button {
                    addSet()
                } label: {
                    Label("Add Set", systemImage: "plus")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.vertical, 5)
                        .foregroundStyle(.primary)
                }
                .listRowBackground(Color.clear)
                .buttonStyle(.glassProminent)
                .buttonSizing(.flexible)
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .dynamicTypeSize(...DynamicTypeSize.large)
        }
    }
    
    var headerView: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(exercise.name)
                        .font(.title3)
                        .bold()
                    Text(exercise.displayMuscle)
                        .foregroundStyle(.secondary)
                        .fontWeight(.semibold)
                    Text("Rep Range: \(exercise.repRange.displayText)")
                        .fontWeight(.semibold)
                }
                Spacer()
                Button("Notes", systemImage: isNotesExpanded ? "note.text" : "note.text.badge.plus") {
                    isNotesExpanded.toggle()
                }
                .labelStyle(.iconOnly)
                .font(.title)
                .tint(.primary)
            }
            
            if isNotesExpanded {
                TextField("Notes", text: $exercise.notes, axis: .vertical)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .listRowBackground(Color.clear)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        .listRowSeparator(.hidden)
    }
    
    private func addSet() {
        if let previous = exercise.sets.last {
            exercise.sets.append(ExerciseSet(weight: previous.weight, reps: previous.reps))
        } else {
            exercise.sets.append(ExerciseSet())
        }
        try? context.save()
    }
}

#Preview {
    ExerciseView(exercise: Workout.sampleData.first!.exercises.first!)
}
