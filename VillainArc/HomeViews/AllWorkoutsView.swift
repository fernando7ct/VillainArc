import SwiftUI
import SwiftData

struct AllWorkoutsView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Workout> { $0.template == false }, sort: \Workout.startTime, order: .reverse, animation: .smooth) private var workouts: [Workout]
    @State private var isEditing = false
    @State private var showDeleteAllAlert = false
    @State private var existingWorkout: Workout? = nil
    
    private func deleteWorkout(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let workoutToDelete = workouts[index]
                DataManager.shared.deleteWorkout(workout: workoutToDelete, context: context)
            }
            HapticManager.instance.impact(style: .light)
        }
    }
    private func deleteAllWorkouts() {
        withAnimation {
            for workout in workouts {
                DataManager.shared.deleteWorkout(workout: workout, context: context)
            }
            HapticManager.instance.impact(style: .heavy)
        }
    }
    
    var body: some View {
        List {
            ForEach(workouts) { workout in
                Section {
                    NavigationLink(value: workout) {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                VStack(alignment: .trailing, spacing: 0) {
                                    Text(workout.title)
                                    Text(workout.startTime, format: .dateTime.month().day().year())
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .fontWeight(.semibold)
                            }
                            .hSpacing(.trailing)
                            .padding(.bottom, 3)
                            ForEach(workout.exercises.sorted(by: { $0.order < $1.order})) { exercise in
                                HStack(spacing: 1) {
                                    Text("\(exercise.sets.count)x")
                                        .foregroundStyle(Color.primary)
                                    Text(exercise.name)
                                        .foregroundStyle(Color.secondary)
                                }
                                .lineLimit(1)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.top, 3)
                            }
                        }
                    }
                    .contextMenu {
                        Button {
                            existingWorkout = workout
                        } label: {
                            Label("Use", systemImage: "figure.strengthtraining.traditional")
                        }
                        Button(role: .destructive) {
                            if let index = workouts.firstIndex(where: { $0.id == workout.id }) {
                                deleteWorkout(at: IndexSet(integer: index))
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .onDelete(perform: deleteWorkout)
            .listRowBackground(BlurView())
            .listRowSeparator(.hidden)
        }
        .scrollContentBackground(.hidden)
        .environment(\.editMode, isEditing ? .constant(.active) : .constant(.inactive))
        .navigationTitle("Workouts")
        .navigationBarBackButtonHidden(isEditing)
        .fullScreenCover(item: $existingWorkout) {
            WorkoutView(existingWorkout: $0)
        }
        .overlay {
            if workouts.isEmpty {
                ContentUnavailableView("You have no past workouts.", systemImage: "figure.strengthtraining.traditional")
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if isEditing {
                    Button {
                        showDeleteAllAlert = true
                    } label: {
                        Text("Delete All")
                            .fontWeight(.semibold)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 9)
                            .foregroundStyle(.white)
                            .background(.red, in: .capsule)
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if !workouts.isEmpty {
                    Button {
                        withAnimation {
                            isEditing.toggle()
                        }
                    } label: {
                        Text(isEditing ? "Done" : "Edit")
                            .fontWeight(.semibold)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 9)
                            .background(.ultraThinMaterial, in: .capsule)
                    }
                }
            }
        }
        .alert(isPresented: $showDeleteAllAlert) {
            Alert(
                title: Text("Delete All Workouts"),
                message: Text("Are you sure you want to delete all workouts?"),
                primaryButton: .destructive(Text("Delete All")) {
                    deleteAllWorkouts()
                },
                secondaryButton: .cancel()
            )
        }
        .background(BackgroundView())
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        AllWorkoutsView()
    }
}
