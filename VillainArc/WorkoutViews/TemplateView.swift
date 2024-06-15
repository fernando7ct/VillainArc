import SwiftUI

struct TemplateView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @FocusState private var notesFocused: Bool
    @State private var exercises: [TempExercise] = []
    @State private var title = "New Template"
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var notes = ""
    @State private var showExerciseSelection = false
    @State private var isEditing = false
    @State private var isTemplate = true
    @State private var showSaveSheet = false
    @State private var selectedExerciseNotes: TempExercise?
    @State private var selectedExerciseTimer: TempExercise?
    
    private func deleteExercise(at offsets: IndexSet) {
        withAnimation {
            exercises.remove(atOffsets: offsets)
            if exercises.isEmpty {
                if isEditing {
                    isEditing.toggle()
                }
            }
        }
    }
    private func moveExercise(from source: IndexSet, to destination: Int) {
        withAnimation {
            exercises.move(fromOffsets: source, toOffset: destination)
        }
    }
    private func addSelectedExercises(_ selectedExercises: [ExerciseSelectionView.Exercise]) {
        for exercise in selectedExercises {
            exercises.append(TempExercise(name: exercise.name, category: exercise.category, repRange: "", notes: "", sets: [TempSet(reps: 0, weight: 0, restMinutes: 0, restSeconds: 0, completed: false)]))
        }
    }
    private func saveWorkout(title: String) {
        DataManager.shared.saveWorkout(exercises: exercises, title: title, notes: notes, startTime: startTime, endTime: endTime, isTemplate: isTemplate, context: context)
        dismiss()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView()
                List {
                    Section {
                        HStack {
                            VStack(alignment: .leading, spacing: 0) {
                                Text(title)
                                    .font(.title)
                                    .fontWeight(.semibold)
                                Text("\(startTime.formatted(.dateTime.month().day().year().weekday(.wide)))")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.secondary)
                            }
                            Spacer()
                            if !isEditing {
                                Menu {
                                    if !exercises.isEmpty {
                                        Button(action: {
                                            showSaveSheet = true
                                        }, label: {
                                            Label("Save Template", systemImage: "checkmark")
                                        })
                                    }
                                    Button(action: {
                                        dismiss()
                                    }, label: {
                                        Label("Cancel Template", systemImage: "xmark")
                                    })
                                    if !exercises.isEmpty {
                                        Button(action: {
                                            withAnimation {
                                                isEditing.toggle()
                                            }
                                        }, label: {
                                            Label("Edit Exercises", systemImage: "list.bullet")
                                        })
                                    }
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
                        .sheet(isPresented: $showSaveSheet) {
                            SaveWorkoutSheet(title: title, exercises: $exercises, notes: $notes, startTime: $startTime, endTime: $endTime, isTemplate: $isTemplate, onSave: { editableTitle in
                                saveWorkout(title: editableTitle)
                            })
                            .interactiveDismissDisabled()
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    if !isEditing {
                        Section {
                            ZStack(alignment: .leading) {
                                TextEditor(text: $notes)
                                    .focused($notesFocused)
                                    .textEditorStyle(.plain)
                                    .autocorrectionDisabled()
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
                        .listRowBackground(Color.clear)
                    }
                    Section {
                        ForEach(exercises.indices, id: \.self) { index in
                            NavigationLink(destination: TemplateExerciseView(exercise: $exercises[index])) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(exercises[index].name)
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(Color.primary)
                                        if !exercises[index].repRange.isEmpty {
                                            Text("Rep Range: \(exercises[index].repRange)")
                                        }
                                        if !exercises[index].notes.isEmpty {
                                            Text("Notes: \(exercises[index].notes.trimmingCharacters(in: .whitespacesAndNewlines))")
                                                .multilineTextAlignment(.leading)
                                                .lineLimit(2)
                                        }
                                        Text(exercises[index].category)
                                        Text("\(exercises[index].sets.count) \(exercises[index].sets.count == 1 ? "set" : "sets")")
                                    }
                                    .font(.subheadline)
                                    .foregroundStyle(Color.secondary)
                                    Spacer()
                                }
                            }
                        }
                        .onDelete(perform: deleteExercise)
                        .onMove(perform: moveExercise)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    if !isEditing {
                        Section {
                            Button(action: {
                                showExerciseSelection = true
                            }, label: {
                                HStack {
                                    Label("Add Exercise", systemImage: "plus")
                                        .fontWeight(.semibold)
                                    Spacer()
                                }
                                .foregroundStyle(Color.primary)
                            })
                            .padding()
                            .background(BlurView())
                            .cornerRadius(12)
                            .sheet(isPresented: $showExerciseSelection) {
                                ExerciseSelectionView(onAdd: addSelectedExercises)
                                    .interactiveDismissDisabled()
                            }
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .environment(\.editMode, isEditing ? .constant(.active) : .constant(.inactive))
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

#Preview {
    TemplateView()
}
