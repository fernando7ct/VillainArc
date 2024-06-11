import SwiftUI
import SwiftData
import ActivityKit

struct WorkoutView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @FocusState private var notesFocused: Bool
    @State private var exercises: [TempExercise] = []
    @State private var title = "New Workout"
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var notes = ""
    @State private var showExerciseSelection = false
    @State private var isEditing = false
    @State private var isTemplate = false
    @State private var showSaveSheet = false
    @StateObject private var timer = TimerDisplayViewModel()
    var existingWorkout: Workout?
    
    @State private var activity: Activity<WorkoutAttributes>?
    func startLiveActivity() {
        let data = currentActiveSet()
        let contentState = WorkoutAttributes.ContentState(exerciesName: currentActiveExercise(), setNumber: data.0, setReps: data.1, setWeight: data.2, date: startTime, isEmpty: exercises.isEmpty)
        let attributes = WorkoutAttributes(workoutTitle: title)
        let activityContent = ActivityContent(state: contentState, staleDate: nil)
        do {
            activity = try Activity<WorkoutAttributes>.request(attributes: attributes, content: activityContent)
        } catch {
            print("Failed to start live activity: \(error)")
        }
    }
    private func updateLiveActivity() {
        let data = currentActiveSet()
        let updatedContentState = WorkoutAttributes.ContentState(
            exerciesName: currentActiveExercise(),
            setNumber: data.0,
            setReps: data.1,
            setWeight: data.2,
            date: startTime,
            isEmpty: exercises.isEmpty
        )
        let updatedContent = ActivityContent(state: updatedContentState, staleDate: nil)
        Task {
            await activity?.update(updatedContent)
        }
    }
    private func currentActiveExercise() -> String {
        for exercise in exercises {
            for set in exercise.sets where !set.completed {
                return exercise.name
            }
        }
        return ""
    }
    private func currentActiveSet() -> (Int, Int, Double) {
        for exercise in exercises {
            for (index, set) in exercise.sets.enumerated() where !set.completed {
                return ((index + 1), (set.reps), (set.weight))
            }
        }
        return (0,0,0)
    }
    private func endLiveActivity() {
        Task {
            await activity?.end(dismissalPolicy: .immediate)
        }
    }
    init(existingWorkout: Workout? = nil) {
        self.existingWorkout = existingWorkout
        if let workout = existingWorkout {
            self._title = State(initialValue: workout.title)
            self._notes = State(initialValue: workout.notes)
            self._isTemplate = State(initialValue: workout.template)
            
            if workout.template {
                self._exercises = State(initialValue: workout.exercises!.sorted(by: { $0.order < $1.order }).compactMap { exercise in
                    return TempExercise(name: exercise.name, category: exercise.category, notes: exercise.notes, sets: [])
                })
            } else {
                self._exercises = State(initialValue: workout.exercises!.sorted(by: { $0.order < $1.order }).map { TempExercise(from: $0) })
            }
        }
    }
    private func fetchLatestExercise(for exerciseName: String) -> WorkoutExercise? {
        let fetchDescriptor = FetchDescriptor<WorkoutExercise>(
            predicate: #Predicate { $0.name == exerciseName },
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
            updateLiveActivity()
        }
    }
    private func completedSets(for exercise: TempExercise) -> Int {
        return exercise.sets.filter { $0.completed }.count
    }
    private func moveExercise(from source: IndexSet, to destination: Int) {
        withAnimation {
            exercises.move(fromOffsets: source, toOffset: destination)
            updateLiveActivity()
        }
    }
    private func addSelectedExercises(_ selectedExercises: [ExerciseSelectionView.Exercise]) {
        for exercise in selectedExercises {
            exercises.append(TempExercise(name: exercise.name, category: exercise.category, notes: "", sets: [TempSet(reps: 0, weight: 0, restMinutes: 0, restSeconds: 0, completed: false)]))
        }
        updateLiveActivity()
    }
    private func saveWorkout(title: String) {
        DataManager.shared.saveWorkout(exercises: exercises, title: title, notes: notes, startTime: startTime, endTime: endTime, isTemplate: isTemplate, context: context)
        timer.endActivity()
        endLiveActivity()
        dismiss()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView()
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(title)
                                .font(.title)
                                .fontWeight(.semibold)
                            Text("\(startTime.formatted(.dateTime.month().day().year().weekday(.wide)))")
                                .font(.subheadline)
                                .foregroundStyle(Color.secondary)
                            HStack(spacing: 0) {
                                Text("Total Time: ")
                                Text(startTime, style: .timer)
                            }
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                        }
                        Spacer()
                        TimerDisplayView(viewModel: timer)
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
                                        showSaveSheet = true
                                    }, label: {
                                        Label("Save Workout", systemImage: "checkmark")
                                    })
                                }
                                Button(action: {
                                    timer.endActivity()
                                    endLiveActivity()
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
                    .sheet(isPresented: $showSaveSheet) {
                        SaveWorkoutSheet(
                            title: title,
                            exercises: $exercises,
                            notes: $notes,
                            startTime: $startTime,
                            endTime: $endTime,
                            isTemplate: $isTemplate,
                            onSave: { editableTitle in
                                saveWorkout(title: editableTitle)
                            }
                        )
                        .interactiveDismissDisabled()
                    }
                    List {
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
                                NavigationLink(destination: ExerciseView(exercise: $exercises[index], timer: timer, updateLiveActivity: updateLiveActivity)) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(exercises[index].name)
                                                .font(.title2)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(Color.primary)
                                            if !exercises[index].notes.isEmpty {
                                                Text("Notes: \(exercises[index].notes.trimmingCharacters(in: .whitespacesAndNewlines))")
                                                    .lineLimit(2)
                                                    .multilineTextAlignment(.leading)
                                            }
                                            Text(exercises[index].category)
                                            Text("\(exercises[index].sets.count) \(exercises[index].sets.count == 1 ? "set" : "sets")")
                                        }
                                        .font(.subheadline)
                                        .foregroundStyle(Color.secondary)
                                        Spacer()
                                        if exercises[index].sets.count != 0 && completedSets(for: exercises[index]) == exercises[index].sets.count {
                                            Text("Sets Completed")
                                                .font(.subheadline)
                                                .foregroundStyle(Color.secondary)
                                        }
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
            .onAppear {
                if isTemplate {
                    let recentExercises = existingWorkout?.exercises!.sorted(by: { $0.order < $1.order }).compactMap { exercise in
                        guard let latestExercise = fetchLatestExercise(for: exercise.name) else {
                            return TempExercise(name: exercise.name, category: exercise.category, notes: exercise.notes, sets: [])
                        }
                        return TempExercise(name: latestExercise.name, category: latestExercise.category, notes: latestExercise.notes, sets: latestExercise.sets!.sorted(by: { $0.order < $1.order }).map { TempSet(from: $0) })
                    }
                    self.exercises = recentExercises ?? []
                    isTemplate = false
                }
                startLiveActivity()
            }
        }
    }
}

#Preview {
    WorkoutView()
}
