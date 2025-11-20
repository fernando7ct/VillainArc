import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Bindable var workout: Workout
    @State private var activeExercise: WorkoutExercise?
    
    @State private var showCancelConfirmation = false
    @State private var showExerciseListView = false
    @State private var showAddExerciseSheet = false
    
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @Namespace private var animation
    
    init(workout: Workout) {
        self.workout = workout
        if let first = workout.exercises.first {
            _activeExercise = .init(initialValue: first)
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if workout.exercises.isEmpty {
                    noExercisesView
                } else if showExerciseListView {
                    exerciseListView
                } else {
                    exerciseTabView
                }
            }
            .navigationTitle(workout.title)
            .toolbarTitleDisplayMode(.inline)
            .navigationSubtitle(Text(workout.startTime, style: .date))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if showExerciseListView {
                        Button("Timer", systemImage: "timer") {
                            
                        }
                    } else {
                        Text(workout.startTime, style: .timer)
                            .frame(width: 40)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add Exercise", systemImage: "plus") {
                        showAddExerciseSheet = true
                    }
                }
                .matchedTransitionSource(id: "AddExercise", in: animation)
                ToolbarItem(placement: .topBarTrailing) {
                    toolBarMenu
                }
            }
            .animation(.bouncy, value: showExerciseListView)
            .background(Color(uiColor: .quaternarySystemFill))
            .sheet(isPresented: $showAddExerciseSheet) {
                AddExerciseView(workout: workout)
                    .navigationTransition(.zoom(sourceID: "AddExercise", in: animation))
                    .interactiveDismissDisabled()
            }
        }
    }
    
    var exerciseTabView: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(workout.exercises) { exercise in
                        ExerciseView(exercise: exercise)
                            .containerRelativeFrame(.horizontal)
                            .id(exercise)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $activeExercise)
            .onAppear {
                if let activeExercise {
                    proxy.scrollTo(activeExercise)
                }
            }
        }
    }
    
    var exerciseListView: some View {
        ScrollView {
            ForEach(workout.exercises) { exercise in
                Button {
                    activeExercise = exercise
                    showExerciseListView = false
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(exercise.name)
                                .font(.title3)
                                .bold()
                            
                            Text(exercise.displayMuscle)
                                .foregroundStyle(.secondary)
                                .fontWeight(.semibold)
                                .font(.headline)
                            ForEach(exercise.sets) { set in
                                Text("\(set.reps)x\(Int(set.weight)) lbs")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .glassEffect(.regular, in: .rect(cornerRadius: 16))
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                }
            }
        }
        .tint(.primary)
        .scrollIndicators(.hidden)
    }
    
    var toolBarMenu: some View {
        Menu("Workout Settings", systemImage: "ellipsis") {
            if !workout.exercises.isEmpty {
                Button(showExerciseListView ? "Exercise View" : "List View",
                       systemImage: showExerciseListView ? "list.clipboard" : "list.dash") {
                    showExerciseListView.toggle()
                }
                Divider()
            }
            Button("Save Workout", systemImage: "checkmark") {
                workout.completed = true
                dismiss()
            }
            .tint(.green)
            Button("Delete Workout", systemImage: "trash", role: .destructive) {
                if !workout.exercises.isEmpty {
                    showCancelConfirmation = true
                } else {
                    deleteWorkout()
                }
            }
        }
        .confirmationDialog("Delete Workout", isPresented: $showCancelConfirmation) {
            Button("Cancel") {
                showCancelConfirmation = false
            }
            Button("Delete", role: .destructive) {
                deleteWorkout()
            }
        } message: {
            Text("Are you sure you want to delete this workout? This cannot be undone.")
        }
    }
    
    var noExercisesView: some View {
        ContentUnavailableView("No Exercises Added", systemImage: "dumbbell.fill", description: Text("Click the '\(Image(systemName: "plus"))' icon to add some exercises." ))
    }
    
    private func deleteWorkout() {
        context.delete(workout)
        dismiss()
    }
}

#Preview {
    WorkoutView(workout: Workout.sampleData.first!)
        .sampleDataConainer()
}
