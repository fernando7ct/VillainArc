import SwiftUI
import SwiftData

struct ExerciseView: View {
    @Query private var exercises: [WorkoutExercise]
    @Environment(\.modelContext) private var context
    @Bindable var exercise: WorkoutExercise
    
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
            ScrollView {
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(exercise.name)
                            .font(.title3)
                            .bold()
                        Text(exercise.displayMuscle)
                            .foregroundStyle(.secondary)
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
                .padding()
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
                .padding(.horizontal)
                
                if !exercise.sets.isEmpty {
                    Grid(horizontalSpacing: 16, verticalSpacing: 10) {
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
                        
                        ForEach(exercise.sets.indices, id: \.self) { index in
                            GridRow {
                                Menu {
                                    Picker("", selection: $exercise.sets[index].type) {
                                        ForEach(ExerciseSetType.allCases) { type in
                                            Text(type.rawValue)
                                                .tag(type)
                                        }
                                    }
                                } label: {
                                    let type = exercise.sets[index].type
                                    Text(type == .regular ? String(index + 1) : type.shortLabel)
                                        .foregroundStyle(type.tintColor)
                                        .frame(width: 40, height: 40)
                                        .glassEffect(.regular, in: .circle)
                                }
                                
                                TextField("Reps", value: $exercise.sets[index].reps, format: .number)
                                    .keyboardType(.numberPad)
                                    .frame(width: geometry.size.width / 5)
                                TextField("Weight", value: $exercise.sets[index].weight, format: .number)
                                    .keyboardType(.decimalPad)
                                    .frame(width: geometry.size.width / 5)
                                Text(previousSetDisplay(for: index))
                                    .lineLimit(1)
                                
                                if exercise.sets[index].complete {
                                    Button {
                                        withAnimation(.bouncy) {
                                            exercise.sets[index].complete.toggle()
                                        }
                                    } label: {
                                        Image(systemName: "checkmark")
                                            .padding(2)
                                    }
                                    .buttonBorderShape(.circle)
                                    .buttonStyle(.glassProminent)
                                    .tint(.green)
                                } else {
                                    Button {
                                        withAnimation(.bouncy) {
                                            exercise.sets[index].complete.toggle()
                                        }
                                    } label: {
                                        Image(systemName: "checkmark")
                                            .padding(2)
                                    }
                                    .labelStyle(.iconOnly)
                                    .buttonBorderShape(.circle)
                                    .buttonStyle(.glass)
                                    .tint(.primary)
                                }
                            }
                            .font(.title3)
                            .fontWeight(.semibold)
                        }
                    }
                    .padding(.vertical)
                }
                
                Button {
                    addSet()
                } label: {
                    Label("Add Set", systemImage: "plus")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.vertical, 5)
                }
                .buttonStyle(.glassProminent)
                .buttonSizing(.flexible)
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .dynamicTypeSize(...DynamicTypeSize.xLarge)
            .animation(.bouncy, value: exercise.sets)
        }
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
