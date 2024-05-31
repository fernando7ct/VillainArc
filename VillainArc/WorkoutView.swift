import SwiftUI

struct WorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var notesFocused: Bool
    @State private var exercises: [TempExercise] = []
    @State private var title = "Blank Workout"
    @State private var startTime = Date()
    @State private var notes = ""
    @State private var showExerciseSelection = false
    @State private var isEditing = false
    
    private func deleteExercise(at offsets: IndexSet) {
        withAnimation {
            exercises.remove(atOffsets: offsets)
        }
    }
    private func moveExercise(from source: IndexSet, to destination: Int) {
        withAnimation {
            exercises.move(fromOffsets: source, toOffset: destination)
        }
    }
    
    private func addSelectedExercises(_ selectedExercises: [ExerciseSelectionView.Exercise]) {
        for exercise in selectedExercises {
            exercises.append(TempExercise(name: exercise.name, category: exercise.category, notes: "", sets: []))
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(title)
                                .font(.title)
                                .fontWeight(.semibold)
                            Text("\(startTime.formatted(.dateTime.month().day().year().weekday(.wide)))")
                                .font(.subheadline)
                                .foregroundStyle(Color.secondary)
                            Text(startTime, style: .timer)
                                .font(.subheadline)
                                .foregroundStyle(Color.secondary)
                        }
                        Spacer()
                        if !isEditing {
                            Menu {
                                if !exercises.isEmpty {
                                    Button(action: {
                                        withAnimation {
                                            isEditing.toggle()
                                        }
                                    }, label: {
                                        Label("Edit Exercises", systemImage: "list.bullet")
                                    })
                                    Button(action: {
                                        
                                    }, label: {
                                        Label("Save Workout", systemImage: "checkmark")
                                    })
                                }
                                Button(action: {
                                    dismiss()
                                }, label: {
                                    Label("Cancel Workout", systemImage: "xmark")
                                })
                            } label: {
                                Image(systemName: "chevron.down.circle")
                                    .font(.title)
                                    .foregroundStyle(Color.primary)
                            }
                        } else {
                            Button(action: {
                                withAnimation {
                                    isEditing.toggle()
                                }
                            }, label: {
                                Text("Done")
                                    .fontWeight(.semibold)
                                    .font(.title2)
                            })
                        }
                    }
                    .padding(.horizontal)
                    
                    List {
                        if !isEditing {
                            Section {
                                ZStack(alignment: .leading) {
                                    TextEditor(text: $notes)
                                        .focused($notesFocused)
                                    if !notesFocused && notes.isEmpty {
                                        Text("Notes...")
                                            .foregroundStyle(.secondary)
                                            .font(.subheadline)
                                            .onTapGesture {
                                                notesFocused = true
                                            }
                                    }
                                }
                            }
                            .listRowSeparator(.hidden)
                        }
                        Section {
                            ForEach(exercises.indices, id: \.self) { index in
                                NavigationLink(destination: ExerciseView(exercise: $exercises[index])) {
                                    VStack(alignment: .leading) {
                                        Text(exercises[index].name)
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                        Text(exercises[index].category)
                                            .font(.subheadline)
                                            .foregroundStyle(Color.secondary)
                                        Text("\(exercises[index].sets.count) \(exercises[index].sets.count == 1 ? "set" : "sets")")
                                            .font(.subheadline)
                                            .foregroundStyle(Color.secondary)
                                    }
                                    .foregroundStyle(Color.primary)
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                            }
                            .onDelete(perform: deleteExercise)
                            .onMove(perform: moveExercise)
                        }
                        .listRowSeparator(.hidden)
                        if !isEditing {
                            Section {
                                Button(action: {
                                    showExerciseSelection = true
                                }, label: {
                                    HStack {
                                        Label("Add New Exercise", systemImage: "plus")
                                        Spacer()
                                    }
                                    .padding(.vertical, 5)
                                    .foregroundStyle(Color.primary)
                                })
                                .buttonStyle(BorderedButtonStyle())
                                .sheet(isPresented: $showExerciseSelection) {
                                    ExerciseSelectionView(onAdd: addSelectedExercises)
                                }
                            }
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .environment(\.editMode, isEditing ? .constant(.active) : .constant(.inactive))
                }
                VStack(alignment: .trailing) {
                    Spacer()
                    HStack(alignment: .bottom) {
                        Spacer()
                        if notesFocused {
                            Button(action: {
                                hideKeyboard()
                                notesFocused = false
                            }, label: {
                                Image(systemName: "keyboard.chevron.compact.down")
                                    .foregroundStyle(Color.primary)
                                    .font(.title)
                            })
                            .buttonStyle(BorderedButtonStyle())
                        }
                    }
                }
                .padding()
            }
        }
    }
}

struct TempExercise: Identifiable {
    var id = UUID()
    var name: String
    var category: String
    var notes: String
    var sets: [TempSet]
    
    init(name: String, category: String, notes: String, sets: [TempSet]) {
        self.name = name
        self.category = category
        self.notes = notes
        self.sets = sets
    }
}

struct TempSet: Identifiable {
    var id = UUID()
    var reps: Int
    var weight: Double
    var completed: Bool
    
    init(reps: Int, weight: Double, completed: Bool) {
        self.reps = reps
        self.weight = weight
        self.completed = completed
    }
}

#Preview {
    WorkoutView()
}
