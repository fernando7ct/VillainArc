import SwiftUI
import SwiftData
import ActivityKit

struct WorkoutView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var exercises: [TempExercise] = []
    @State private var title = "New Workout"
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var notes = ""
    @State private var showExerciseSelection = false
    @State private var isEditingExercises = false
    @State private var isTemplate = false
    @State private var showSaveSheet = false
    @StateObject private var timer = TimerDisplayViewModel()
    @State private var activityStarted = false
    @State private var isEditing = false
    var existingWorkout: Workout?
    @FocusState private var keyboardActive: Bool
    @State private var exerciseToReplaceIndex: Int? = nil
    
    init(existingWorkout: Workout? = nil, isEditing: Bool? = nil) {
        self.existingWorkout = existingWorkout
        if let workout = existingWorkout {
            self._title = State(initialValue: workout.title)
            self._notes = State(initialValue: workout.notes)
            self._isTemplate = State(initialValue: workout.template)
            if isEditing != nil {
                self._startTime = State(initialValue: workout.startTime)
                self._endTime = State(initialValue: workout.endTime)
                self._exercises = State(initialValue: workout.exercises.sorted(by: { $0.order < $1.order }).map { TempExercise(from: $0) })
                self._isEditing = State(initialValue: true)
            } else {
                if !workout.template {
                    self._exercises = State(initialValue: workout.exercises.sorted(by: { $0.order < $1.order }).map { TempExercise(from: $0) })
                }
            }
        }
    }
    private func fetchLatestExercise(for exerciseName: String) -> WorkoutExercise? {
        let fetchDescriptor = FetchDescriptor<WorkoutExercise>(
            predicate: #Predicate { $0.name == exerciseName && $0.workout?.template != true },
            sortBy: [SortDescriptor(\WorkoutExercise.date, order: .reverse)]
        )
        do {
            let results = try context.fetch(fetchDescriptor)
            return results.first
        } catch {
            print("Failed to fetch latest exercise: \(error.localizedDescription)")
            return nil
        }
    }
    private func deleteExercise(at offsets: IndexSet) {
        withAnimation {
            exercises.remove(atOffsets: offsets)
            WorkoutActivityManager.shared.updateLiveActivity(with: exercises, title: title, startTime: startTime, timer: timer)
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
            WorkoutActivityManager.shared.updateLiveActivity(with: exercises, title: title, startTime: startTime, timer: timer)
        }
    }
    private func addSelectedExercises(_ selectedExercises: [ExerciseSelectionView.Exercise]) {
        for exercise in selectedExercises {
            exercises.append(TempExercise(name: exercise.name, category: exercise.category, repRange: "", notes: "", sameRestTimes: false, sets: [TempSet(reps: 0, weight: 0, restMinutes: 0, restSeconds: 0, completed: false)]))
        }
        WorkoutActivityManager.shared.updateLiveActivity(with: exercises, title: title, startTime: startTime, timer: timer)
        HapticManager.instance.impact(style: .medium)
    }
    private func replaceExercise(at index: Int, with exercise: ExerciseSelectionView.Exercise) {
        exercises[index] = TempExercise(name: exercise.name, category: exercise.category, repRange: "", notes: "", sameRestTimes: false, sets: [TempSet(reps: 0, weight: 0, restMinutes: 0, restSeconds: 0, completed: false)])
        WorkoutActivityManager.shared.updateLiveActivity(with: exercises, title: title, startTime: startTime, timer: timer)
        HapticManager.instance.impact(style: .medium)
    }
    private func saveWorkout() {
        if !isEditing {
            DataManager.shared.saveWorkout(exercises: exercises, title: title, notes: notes, startTime: startTime, endTime: endTime, isTemplate: isTemplate, context: context)
            timer.endActivity()
            WorkoutActivityManager.shared.endLiveActivity()
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
                                    .fontWeight(.semibold)
                                    .onChange(of: title) {
                                        WorkoutActivityManager.shared.updateLiveActivity(with: exercises, title: title, startTime: startTime, timer: timer)
                                    }
                                Text(startTime, format: .dateTime.month().day().year().weekday(.wide))
                                    .textScale(.secondary)
                                    .foregroundStyle(.secondary)
                                if !isEditing {
                                    HStack(spacing: 0) {
                                        Text("Total Time: ")
                                        Text(startTime, style: .timer)
                                    }
                                    .textScale(.secondary)
                                    .foregroundStyle(.secondary)
                                } else {
                                    Text("Total Time: \(totalWorkoutTime(startTime: startTime, endTime: endTime))")
                                        .textScale(.secondary)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            TimerDisplayView(viewModel: timer)
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
                                        if !isEditing {
                                            timer.endActivity()
                                            WorkoutActivityManager.shared.endLiveActivity()
                                        }
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
                            SaveWorkoutSheet(title: $title, exercises: $exercises, notes: $notes, startTime: $startTime, endTime: $endTime, isTemplate: isTemplate, isEditing: isEditing, onSave: saveWorkout)
                                .interactiveDismissDisabled()
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    if !isEditingExercises {
                        Section {
                            TextField("Workout Notes", text: $notes, axis: .vertical)
                                .textEditorStyle(.plain)
                                .autocorrectionDisabled()
                                .focused($keyboardActive)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    Section {
                        ForEach(exercises.indices, id: \.self) { index in
                            NavigationLink(destination: ExerciseView(exercise: $exercises[index], timer: timer, isEditing: isEditing, updateLiveActivity: {
                                WorkoutActivityManager.shared.updateLiveActivity(with: exercises, title: title, startTime: startTime, timer: timer)
                            }, deleteExercise: {
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
                        if keyboardActive {
                            Button {
                                hideKeyboard()
                                keyboardActive = false
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
            .onAppear {
                if isTemplate {
                    let recentExercises = existingWorkout?.exercises.sorted(by: { $0.order < $1.order }).compactMap { exercise in
                        guard let latestExercise = fetchLatestExercise(for: exercise.name) else {
                            return TempExercise(name: exercise.name, category: exercise.category, repRange: exercise.repRange, notes: exercise.notes, sameRestTimes: exercise.sameRestTimes, sets: [])
                        }
                        return TempExercise(name: latestExercise.name, category: latestExercise.category, repRange: exercise.repRange, notes: exercise.notes, sameRestTimes: exercise.sameRestTimes, sets: latestExercise.sets.sorted(by: { $0.order < $1.order }).map { TempSet(from: $0) })
                    }
                    self.exercises = recentExercises ?? []
                    isTemplate = false
                }
                if !activityStarted && !isEditing {
                    WorkoutActivityManager.shared.startLiveActivity(with: exercises, title: title, startTime: startTime)
                    activityStarted.toggle()
                }
            }
        }
    }
}

#Preview {
    WorkoutView()
}

struct WorkoutExerciseRowView: View {
    var exercise: TempExercise
    
    private func completedSets(for exercise: TempExercise) -> Int {
        return exercise.sets.filter { $0.completed }.count
    }
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(exercise.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primary)
                if !exercise.repRange.isEmpty {
                    Text("Rep Range: \(exercise.repRange)")
                }
                if !exercise.notes.isEmpty {
                    Text("Notes: \(exercise.notes.trimmingCharacters(in: .whitespacesAndNewlines))")
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Text(exercise.category)
                Text("\(exercise.sets.count) \(exercise.sets.count == 1 ? "set" : "sets")")
            }
            .textScale(.secondary)
            .foregroundStyle(.secondary)
            Spacer()
            if exercise.sets.count != 0 && completedSets(for: exercise) == exercise.sets.count {
                Text("Sets Completed")
                    .textScale(.secondary)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
