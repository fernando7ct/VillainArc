//import SwiftUI
//import SwiftData
//import ActivityKit
//
//struct Testing: View {
//    @Environment(\.modelContext) private var context
//    @Environment(\.dismiss) private var dismiss
//    @State private var exercises: [TempExercise] = []
//    @State private var title = "New Workout"
//    @State private var startTime = Date()
//    @State private var endTime = Date()
//    @State private var notes = ""
//    @State private var showExerciseSelection = false
//    @State private var isEditingExercises = false
//    @State private var isTemplate = false
//    @State private var showSaveSheet = false
//    @StateObject private var timer = TimerDisplayViewModel()
//    @State private var activityStarted = false
//    @State private var isEditing = false
//    var existingWorkout: Workout?
//    @State private var activity: Activity<WorkoutAttributes>?
//    
//    func startLiveActivity() {
//        let data = currentActiveSet()
//        let contentState = WorkoutAttributes.ContentState(exerciesName: currentActiveExercise(), setNumber: data.0, setReps: data.1, setWeight: data.2, date: startTime, isEmpty: exercises.isEmpty)
//        let attributes = WorkoutAttributes(workoutTitle: title)
//        let activityContent = ActivityContent(state: contentState, staleDate: nil)
//        do {
//            activity = try Activity<WorkoutAttributes>.request(attributes: attributes, content: activityContent)
//        } catch {
//            print("Failed to start live activity: \(error)")
//        }
//    }
//    private func updateLiveActivity() {
//        let data = currentActiveSet()
//        let updatedContentState = WorkoutAttributes.ContentState(
//            exerciesName: currentActiveExercise(),
//            setNumber: data.0,
//            setReps: data.1,
//            setWeight: data.2,
//            date: startTime,
//            isEmpty: exercises.isEmpty
//        )
//        let updatedContent = ActivityContent(state: updatedContentState, staleDate: nil)
//        Task {
//            await activity?.update(updatedContent)
//        }
//    }
//    private func currentActiveExercise() -> String {
//        for exercise in exercises {
//            for set in exercise.sets where !set.completed {
//                return exercise.name
//            }
//        }
//        return ""
//    }
//    private func currentActiveSet() -> (Int, Int, Double) {
//        for exercise in exercises {
//            for (index, set) in exercise.sets.enumerated() where !set.completed {
//                return ((index + 1), (set.reps), (set.weight))
//            }
//        }
//        return (0,0,0)
//    }
//    private func endLiveActivity() {
//        Task {
//            await activity?.end(dismissalPolicy: .immediate)
//        }
//    }
//    init(existingWorkout: Workout? = nil, isEditing: Bool? = nil) {
//        self.existingWorkout = existingWorkout
//        if isEditing != nil {
//            if let workout = existingWorkout {
//                self._title = State(initialValue: workout.title)
//                self._notes = State(initialValue: workout.notes)
//                self._isTemplate = State(initialValue: workout.template)
//                self._startTime = State(initialValue: workout.startTime)
//                self._endTime = State(initialValue: workout.endTime)
//                self._exercises = State(initialValue: workout.exercises.sorted(by: { $0.order < $1.order }).map { TempExercise(from: $0) })
//                self._isEditing = State(initialValue: true)
//            }
//        } else {
//            if let workout = existingWorkout {
//                self._title = State(initialValue: workout.title)
//                self._notes = State(initialValue: workout.notes)
//                self._isTemplate = State(initialValue: workout.template)
//                
//                if workout.template {
//                    self._exercises = State(initialValue: workout.exercises.sorted(by: { $0.order < $1.order }).compactMap { exercise in
//                        return TempExercise(name: exercise.name, category: exercise.category, repRange: exercise.repRange, notes: exercise.notes, sets: [])
//                    })
//                } else {
//                    self._exercises = State(initialValue: workout.exercises.sorted(by: { $0.order < $1.order }).map { TempExercise(from: $0) })
//                }
//            }
//        }
//    }
//    private func fetchLatestExercise(for exerciseName: String) -> WorkoutExercise? {
//        let fetchDescriptor = FetchDescriptor<WorkoutExercise>(
//            predicate: #Predicate { $0.name == exerciseName && $0.workout?.template != true },
//            sortBy: [SortDescriptor(\WorkoutExercise.date, order: .reverse)]
//        )
//        do {
//            let results = try context.fetch(fetchDescriptor)
//            return results.first
//        } catch {
//            print("Failed to fetch latest exercise: \(error.localizedDescription)")
//            return nil
//        }
//    }
//    private func deleteExercise(at offsets: IndexSet) {
//        withAnimation {
//            exercises.remove(atOffsets: offsets)
//            updateLiveActivity()
//            HapticManager.instance.impact(style: .light)
//            if exercises.isEmpty {
//                if isEditingExercises {
//                    isEditingExercises.toggle()
//                }
//            }
//        }
//    }
//    private func completedSets(for exercise: TempExercise) -> Int {
//        return exercise.sets.filter { $0.completed }.count
//    }
//    private func moveExercise(from source: IndexSet, to destination: Int) {
//        withAnimation {
//            exercises.move(fromOffsets: source, toOffset: destination)
//            updateLiveActivity()
//        }
//    }
//    private func addSelectedExercises(_ selectedExercises: [ExerciseSelectionView.Exercise]) {
//        for exercise in selectedExercises {
//            exercises.append(TempExercise(name: exercise.name, category: exercise.category, repRange: "", notes: "", sets: [TempSet(reps: 0, weight: 0, restMinutes: 0, restSeconds: 0, completed: false)]))
//        }
//        updateLiveActivity()
//        HapticManager.instance.impact(style: .medium)
//    }
//    private func saveWorkout() {
//        if !isEditing {
//            DataManager.shared.saveWorkout(exercises: exercises, title: title, notes: notes, startTime: startTime, endTime: endTime, isTemplate: isTemplate, context: context)
//            timer.endActivity()
//            endLiveActivity()
//        } else {
//            DataManager.shared.updateWorkout(exercises: exercises, title: title, notes: notes, startTime: startTime, endTime: endTime, isTemplate: isTemplate, workout: existingWorkout, context: context)
//        }
//        HapticManager.instance.notification(type: .success)
//        dismiss()
//    }
//    var body: some View {
//        ZStack {
//            BackgroundView()
//            VStack(spacing: 15) {
//                HStack(alignment: .top) {
//                    VStack(alignment: .leading, spacing: 0) {
//                        TextField("Workout Title", text: $title)
//                            .font(.title)
//                            .fontWeight(.semibold)
//                        Text(startTime, style: .date)
//                            .textScale(.secondary)
//                            .foregroundStyle(.secondary)
//                        if !isEditing {
//                            HStack(spacing: 0) {
//                                Text("Total Time: ")
//                                Text(startTime, style: .timer)
//                            }
//                            .textScale(.secondary)
//                            .foregroundStyle(.secondary)
//                        } else {
//                            Text("Total Time: \(totalWorkoutTime(startTime: startTime, endTime: endTime))")
//                                .textScale(.secondary)
//                                .foregroundStyle(.secondary)
//                        }
//                    }
//                    Spacer()
//                    VStack(alignment: .trailing, spacing: 10) {
//                        if !isEditingExercises {
//                            Menu {
//                                if !exercises.isEmpty {
//                                    Button {
//                                        showSaveSheet = true
//                                    } label: {
//                                        Label(isEditing ? "Update" : "Save", systemImage: "checkmark")
//                                    }
//                                }
//                                if !exercises.isEmpty {
//                                    Button {
//                                        withAnimation {
//                                            isEditingExercises.toggle()
//                                        }
//                                    } label: {
//                                        Label("Edit Exercises", systemImage: "list.bullet")
//                                    }
//                                }
//                                Button(role: .destructive) {
//                                    if !isEditing {
//                                        timer.endActivity()
//                                        endLiveActivity()
//                                    }
//                                    dismiss()
//                                } label: {
//                                    Label("Cancel", systemImage: "xmark")
//                                }
//                            } label: {
//                                Image(systemName: "chevron.down.circle")
//                                    .font(.title)
//                            }
//                        } else {
//                            Button {
//                                withAnimation {
//                                    isEditingExercises.toggle()
//                                }
//                            } label: {
//                                Text("Done")
//                                    .fontWeight(.semibold)
//                                    .font(.title2)
//                            }
//                        }
//                        TimerDisplayView(viewModel: timer)
//                    }
//                }
//                .padding(.horizontal)
//                .padding(.vertical, 5)
//                .background {
//                    RoundedRectangle(cornerRadius: 8, style: .continuous)
//                        .fill(.ultraThinMaterial)
//                }
//                .padding(.horizontal)
//                
//                if !isEditingExercises {
//                    TextField("Workout Notes", text: $notes, axis: .vertical)
//                        .autocorrectionDisabled()
//                        .padding(.horizontal)
//                }
//                if !isEditingExercises {
//                    TabView {
//                        ForEach($exercises) {
//                            TestingExerciseView(exercise: $0, timer: timer, isEditing: isEditing, updateLiveActivity: updateLiveActivity)
//                        }
//                    }
//                    .tabViewStyle(.page(indexDisplayMode: .never))
//                } else {
//                    List {
//                        ForEach(exercises.indices, id: \.self) { index in
//                                HStack {
//                                    VStack(alignment: .leading) {
//                                        Text(exercises[index].name)
//                                            .font(.title2)
//                                            .fontWeight(.semibold)
//                                            .foregroundStyle(Color.primary)
//                                        if !exercises[index].repRange.isEmpty {
//                                            Text("Rep Range: \(exercises[index].repRange)")
//                                        }
//                                        if !exercises[index].notes.isEmpty {
//                                            Text("Notes: \(exercises[index].notes.trimmingCharacters(in: .whitespacesAndNewlines))")
//                                                .lineLimit(2)
//                                                .multilineTextAlignment(.leading)
//                                        }
//                                        Text(exercises[index].category)
//                                        Text("\(exercises[index].sets.count) \(exercises[index].sets.count == 1 ? "set" : "sets")")
//                                    }
//                                    .font(.subheadline)
//                                    .foregroundStyle(Color.secondary)
//                                    Spacer()
//                                    if exercises[index].sets.count != 0 && completedSets(for: exercises[index]) == exercises[index].sets.count {
//                                        Text("Sets Completed")
//                                            .font(.subheadline)
//                                            .foregroundStyle(Color.secondary)
//                                    }
//                                }
//                        }
//                        .onDelete(perform: deleteExercise)
//                        .onMove(perform: moveExercise)
//                    }
//                    .listStyle(.plain)
//                    .environment(\.editMode, isEditingExercises ? .constant(.active) : .constant(.inactive))
//                }
//            }
//        }
//        .onAppear {
//            if isTemplate {
//                let recentExercises = existingWorkout?.exercises.sorted(by: { $0.order < $1.order }).compactMap { exercise in
//                    guard let latestExercise = fetchLatestExercise(for: exercise.name) else {
//                        return TempExercise(name: exercise.name, category: exercise.category, repRange: exercise.repRange, notes: exercise.notes, sets: [])
//                    }
//                    return TempExercise(name: latestExercise.name, category: latestExercise.category, repRange: exercise.repRange, notes: exercise.notes, sets: latestExercise.sets.sorted(by: { $0.order < $1.order }).map { TempSet(from: $0) })
//                }
//                self.exercises = recentExercises ?? []
//                isTemplate = false
//            }
//            if !activityStarted && !isEditing {
//                startLiveActivity()
//                activityStarted.toggle()
//            }
//        }
//        .onTapGesture {
//            hideKeyboard()
//        }
//    }
//}
//
//struct TestingExerciseView: View {
//    @Binding var exercise: TempExercise
//    @ObservedObject var timer: TimerDisplayViewModel
//    var isEditing: Bool
//    @State private var showHistorySheet = false
//    @State private var setRestTimeSheet = false
//    @State private var setRepRangeSheet = false
//    let updateLiveActivity: () -> Void
//    
//    private func populateSets(from historySets: [TempSet], notes: String?, repRange: String?) {
//        exercise.sets = historySets
//        if let notes = notes {
//            exercise.notes = notes
//        }
//        if let repRange = repRange {
//            exercise.repRange = repRange
//        }
//        updateLiveActivity()
//    }
//    private func deleteSet(at index: Int) {
//        exercise.sets.remove(at: index)
//        HapticManager.instance.impact(style: .light)
//        updateLiveActivity()
//    }
//    
//    var body: some View {
//        List {
//            Section {
//                HStack(alignment: .top) {
//                    VStack(alignment: .leading, spacing: 0) {
//                        Text(exercise.name)
//                            .font(.title3)
//                            .fontWeight(.semibold)
//                            .lineLimit(1)
//                        Text("Rep Range: \(exercise.repRange.isEmpty ? "Not Set" : exercise.repRange)")
//                            .textScale(.secondary)
//                            .foregroundStyle(.secondary)
//                        Text(exercise.category)
//                            .textScale(.secondary)
//                            .foregroundStyle(.secondary)
//                    }
//                    Spacer()
//                    Menu {
//                        if !exercise.sets.isEmpty {
//                            Button {
//                                setRestTimeSheet.toggle()
//                            } label: {
//                                Label("Rest Times", systemImage: "timer")
//                            }
//                        }
//                        Button {
//                            setRepRangeSheet.toggle()
//                        } label: {
//                            Label("Rep Range", systemImage: "alternatingcurrent")
//                        }
//                        Button {
//                            showHistorySheet.toggle()
//                        } label: {
//                            Label("History", systemImage: "clock")
//                        }
//                    } label: {
//                        Image(systemName: "ellipsis")
//                            .font(.title2)
//                    }
//                    .tint(.secondary)
//                    .padding(.top, 5)
//                    .sheet(isPresented: $showHistorySheet) {
//                        ExerciseHistoryView(exerciseName: $exercise.name, onSelectHistory: populateSets)
//                            .presentationDragIndicator(.visible)
//                            .presentationDetents([.medium, .large])
//                    }
//                    .sheet(isPresented: $setRestTimeSheet) {
//                        SetRestTimeView(exercise: $exercise)
//                            .presentationDragIndicator(.visible)
//                            .presentationDetents([.medium, .large])
//                    }
//                    .sheet(isPresented: $setRepRangeSheet) {
//                        SetRepRangeView(exercise: $exercise)
//                            .interactiveDismissDisabled()
//                            .presentationDetents([.medium])
//                    }
//                }
//            }
//            .listRowSeparator(.hidden)
//            .listRowBackground(Color.clear)
//            Section {
//                TextField("Exercise Notes", text: $exercise.notes, axis: .vertical)
//                    .autocorrectionDisabled()
//                    .textScale(.secondary)
//            }
//            .listRowSeparator(.hidden)
//            .listRowBackground(Color.clear)
//            Section {
//                if !exercise.sets.isEmpty {
//                    HStack {
//                        Text("Set")
//                            .padding(.trailing)
//                        Text("Reps")
//                        Spacer()
//                        Text("Weight")
//                        Spacer()
//                    }
//                    .fontWeight(.semibold)
//                    .font(.title2)
//                }
//                ForEach(exercise.sets.indices, id: \.self) { index in
//                    ExerciseSetRowView(set: $exercise.sets[index], index: index, timer: timer, isEditing: isEditing, updateLiveActivity: updateLiveActivity, deleteSet: deleteSet)
//                }
//            }
//            .listRowSeparator(.hidden)
//            .listRowBackground(Color.clear)
//            Section {
//                Button {
//                    withAnimation {
//                        if exercise.sets.isEmpty {
//                            exercise.sets.append(TempSet(reps: 0, weight: 0, restMinutes: 0, restSeconds: 0, completed: false))
//                        } else {
//                            let lastSet = exercise.sets.last!
//                            exercise.sets.append(TempSet(reps: lastSet.reps, weight: lastSet.weight, restMinutes: lastSet.restMinutes, restSeconds: lastSet.restSeconds, completed: false))
//                        }
//                        updateLiveActivity()
//                    }
//                    HapticManager.instance.impact(style: .light)
//                } label: {
//                    HStack {
//                        Label("Add Set", systemImage: "plus")
//                            .fontWeight(.semibold)
//                        Spacer()
//                    }
//                }
//                .padding()
//                .buttonStyle(BorderlessButtonStyle())
//                .background {
//                    RoundedRectangle(cornerRadius: 8, style: .continuous)
//                        .fill(.ultraThinMaterial)
//                }
//            }
//            .listRowSeparator(.hidden)
//            .listRowBackground(Color.clear)
//        }
//        .scrollContentBackground(.hidden)
//        .listStyle(.plain)
//        .background {
//            RoundedRectangle(cornerRadius: 8, style: .continuous)
//                .fill(.ultraThinMaterial)
//        }
//        .padding(.horizontal)
//    }
//}
//
//struct ExerciseSetRowView: View {
//    @Binding var set: TempSet
//    var index: Int
//    @ObservedObject var timer: TimerDisplayViewModel
//    var isEditing: Bool
//    let updateLiveActivity: () -> Void
//    let deleteSet: (Int) -> Void
//    
//    var body: some View {
//        HStack {
//            Text("\(index + 1)")
//                .padding(.horizontal)
//                .padding(.vertical, 7)
//                .background {
//                    RoundedRectangle(cornerRadius: 8, style: .continuous)
//                        .fill(.ultraThinMaterial)
//                }
//            TextField("", value: $set.reps, format: .number)
//                .keyboardType(.numberPad)
//                .padding(.horizontal)
//                .padding(.vertical, 7)
//                .background {
//                    RoundedRectangle(cornerRadius: 8, style: .continuous)
//                        .fill(.ultraThinMaterial)
//                }
//                .onChange(of: set.reps) {
//                    updateLiveActivity()
//                }
//            TextField("", value: $set.weight, format: .number)
//                .keyboardType(.decimalPad)
//                .padding(.horizontal)
//                .padding(.vertical, 7)
//                .background {
//                    RoundedRectangle(cornerRadius: 8, style: .continuous)
//                        .fill(.ultraThinMaterial)
//                }
//                .onChange(of: set.weight) {
//                    updateLiveActivity()
//                }
//        }
//        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
//            Button(role: .destructive) {
//                deleteSet(index)
//            } label: {
//                Label("Delete", systemImage: "trash")
//            }
//            .buttonStyle(BorderlessButtonStyle())
//        }
//        .swipeActions(edge: .leading, allowsFullSwipe: true) {
//            if !isEditing {
//                Button {
//                    if !set.completed {
//                        timer.startRestTimer(minutes: set.restMinutes, seconds: set.restSeconds)
//                        HapticManager.instance.impact(style: .light)
//                    }
//                    set.completed.toggle()
//                    updateLiveActivity()
//                } label: {
//                    Image(systemName: set.completed ? "xmark" : "checkmark")
//                }
//                .tint(set.completed ? .red : .green)
//                .buttonStyle(BorderlessButtonStyle())
//            }
//        }
//    }
//}
//
//#Preview {
//    Testing()
//}
