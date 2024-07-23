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
    @State private var isEditingExercises = false
    @State private var showSaveSheet = false
    @State private var existingWorkout: Workout?
    @State private var isEditing = false
    @State private var exerciseToReplaceIndex: Int? = nil
    
    init(existingWorkout: Workout? = nil) {
        self._existingWorkout = State(initialValue: existingWorkout)
        if let workout = existingWorkout {
            self._title = State(initialValue: workout.title)
            self._notes = State(initialValue: workout.notes)
            self._startTime = State(initialValue: workout.startTime)
            self._endTime = State(initialValue: workout.endTime)
            self._exercises = State(initialValue: workout.exercises.sorted(by: { $0.order < $1.order }).map { TempExercise(from: $0) })
            self._isEditing = State(initialValue: true)
        }
    }
    
    private func deleteExercise(at offsets: IndexSet) {
        withAnimation {
            exercises.remove(atOffsets: offsets)
            HapticManager.instance.impact(style: .light)
            if exercises.isEmpty {
                if isEditingExercises {
                    isEditingExercises.toggle()
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
            exercises.append(TempExercise(name: exercise.name, category: exercise.category, repRange: "", notes: "", sameRestTimes: false, sets: [TempSet(reps: 0, weight: 0, restMinutes: 0, restSeconds: 0, completed: false)]))
        }
        HapticManager.instance.impact(style: .light)
    }
    private func replaceExercise(at index: Int, with exercise: ExerciseSelectionView.Exercise) {
        exercises[index] = TempExercise(name: exercise.name, category: exercise.category, repRange: "", notes: "", sameRestTimes: false, sets: [TempSet(reps: 0, weight: 0, restMinutes: 0, restSeconds: 0, completed: false)])
        HapticManager.instance.impact(style: .medium)
    }
    private func saveWorkout() {
        if !isEditing {
            DataManager.shared.saveWorkout(exercises: exercises, title: title, notes: notes, startTime: startTime, endTime: endTime, isTemplate: true, context: context)
        } else {
            DataManager.shared.updateWorkout(exercises: exercises, title: title, notes: notes, startTime: startTime, endTime: endTime, workout: existingWorkout, context: context)
        }
        HapticManager.instance.notification(type: .success)
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
                                TextField("Title", text: $title)
                                    .font(.title)
                                    .textFieldStyle(.plain)
                                    .fontWeight(.semibold)
                                Text("\(startTime.formatted(.dateTime.month().day().year().weekday(.wide)))")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.secondary)
                            }
                            Spacer()
                            if !isEditingExercises {
                                Menu {
                                    if !exercises.isEmpty {
                                        Button {
                                            showSaveSheet = true
                                        } label: {
                                            Label(isEditing ? "Update" : "Save", systemImage: "checkmark")
                                        }
                                    }
                                    if !exercises.isEmpty {
                                        Button {
                                            withAnimation {
                                                isEditingExercises.toggle()
                                            }
                                        } label: {
                                            Label("Edit Exercises", systemImage: "list.bullet")
                                        }
                                    }
                                    Button(role: .destructive) {
                                        dismiss()
                                    } label: {
                                        Label("Cancel", systemImage: "xmark")
                                    }
                                } label: {
                                    Image(systemName: "chevron.down.circle")
                                        .font(.title)
                                        .foregroundStyle(Color.primary)
                                }
                            } else {
                                Button {
                                    withAnimation {
                                        isEditingExercises.toggle()
                                    }
                                } label: {
                                    Text("Done")
                                        .fontWeight(.semibold)
                                        .font(.title2)
                                }
                            }
                        }
                        .sheet(isPresented: $showSaveSheet) {
                            SaveWorkoutSheet(title: $title, exercises: $exercises, notes: $notes, startTime: $startTime, endTime: $endTime, isTemplate: true, isEditing: isEditing, onSave:
                                                saveWorkout)
                            .interactiveDismissDisabled()
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    if !isEditingExercises {
                        Section {
                            TextField("Template Notes", text: $notes, axis: .vertical)
                                .focused($notesFocused)
                                .textEditorStyle(.plain)
                                .autocorrectionDisabled()
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    Section {
                        ForEach(exercises.indices, id: \.self) { index in
                            NavigationLink(destination: TemplateExerciseView(exercise: $exercises[index], deleteExercise: {
                                deleteExercise(at: IndexSet(integer: index))
                            })) {
                                WorkoutExerciseRowView(exercise: exercises[index])
                            }
                            .contextMenu {
                                if !isEditingExercises {
                                    Button {
                                        exerciseToReplaceIndex = index
                                        showExerciseSelection.toggle()
                                    } label: {
                                        Label("Replace Exercise", systemImage: "arrow.triangle.2.circlepath")
                                    }
                                    Button {
                                        withAnimation {
                                            isEditingExercises.toggle()
                                        }
                                    } label: {
                                        Label("Edit Exercises", systemImage: "list.bullet")
                                    }
                                    Button(role: .destructive) {
                                        deleteExercise(at: IndexSet(integer: index))
                                    } label: {
                                        Label("Delete Exercise", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteExercise)
                        .onMove(perform: moveExercise)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    if !isEditingExercises {
                        Section {
                            Button {
                                showExerciseSelection = true
                            } label: {
                                HStack {
                                    Label("Add Exercise", systemImage: "plus")
                                        .fontWeight(.semibold)
                                }
                                .hSpacing(.leading)
                                .foregroundStyle(Color.primary)
                            }
                            .padding()
                            .background(BlurView())
                            .cornerRadius(12)
                            .sheet(isPresented: $showExerciseSelection) {
                                ExerciseSelectionView(exerciseToReplaceIndex: $exerciseToReplaceIndex, onAdd: addSelectedExercises, onReplace: replaceExercise)
                                    .interactiveDismissDisabled()
                            }
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .environment(\.editMode, isEditingExercises ? .constant(.active) : .constant(.inactive))
                VStack(alignment: .trailing) {
                    Spacer()
                    HStack(alignment: .bottom) {
                        Spacer()
                        if notesFocused {
                            Button {
                                hideKeyboard()
                                notesFocused = false
                            } label: {
                                Image(systemName: "keyboard.chevron.compact.down")
                                    .foregroundStyle(Color.primary)
                                    .font(.title)
                            }
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
