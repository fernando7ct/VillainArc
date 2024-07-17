import SwiftUI
import SwiftData

struct AllWorkoutsView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Workout> { workout in
        !workout.template
    }, sort: \Workout.startTime, order: .reverse, animation: .smooth) private var workouts: [Workout]
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
        }
    }
    
    var body: some View {
        ZStack {
            BackgroundView()
            List {
                ForEach(workouts) { workout in
                    Section {
                        NavigationLink(value: workout) {
                            VStack(alignment: .leading, spacing: 0) {
                                HStack {
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 0) {
                                        Text(workout.title)
                                        Text("\(workout.startTime.formatted(.dateTime.month().day().year()))")
                                            .font(.caption2)
                                            .foregroundStyle(Color.secondary)
                                    }
                                    .fontWeight(.semibold)
                                }
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
            .navigationTitle("All Workouts")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
            .navigationBarBackButtonHidden(isEditing)
            .fullScreenCover(item: $existingWorkout) { workout in
                WorkoutView(existingWorkout: workout)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button {
                            showDeleteAllAlert = true
                        } label: {
                            Text("Delete All")
                                .foregroundColor(.red)
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
        }
    }
}

#Preview {
    AllWorkoutsView()
}
