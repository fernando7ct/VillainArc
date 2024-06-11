import SwiftUI
import SwiftData

struct AllWorkoutsView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Workout> { workout in
        !workout.template
    }, sort: \Workout.startTime, order: .reverse) private var workouts: [Workout]
    @State private var isEditing = false
    @State private var showDeleteAllAlert = false
    
    private func deleteWorkout(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let workoutToDelete = workouts[index]
                DataManager.shared.deleteWorkout(workout: workoutToDelete, context: context)
            }
        }
    }
    private func deleteAllWorkouts() {
        withAnimation {
            for workout in workouts {
                DataManager.shared.deleteWorkout(workout: workout, context: context)
            }
            isEditing.toggle()
        }
    }
    
    var body: some View {
        ZStack {
            BackgroundView()
            List {
                ForEach(workouts) { workout in
                    NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(workout.title)
                                    .fontWeight(.semibold)
                                Text(concatenatedExerciseNames(for: workout))
                                    .lineLimit(2)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            Text("\(workout.startTime.formatted(.dateTime.month().day().year()))")
                                .font(.subheadline)
                                .foregroundStyle(Color.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteWorkout)
                .listRowBackground(BlurView())
            }
            .scrollContentBackground(.hidden)
            .environment(\.editMode, isEditing ? .constant(.active) : .constant(.inactive))
            .overlay {
                if workouts.isEmpty {
                    ContentUnavailableView("You have no workouts.", systemImage: "dumbbell")
                }
            }
            .navigationTitle("All Workouts")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
            .navigationBarBackButtonHidden(isEditing && !workouts.isEmpty)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing && !workouts.isEmpty {
                        Button(action: {
                            showDeleteAllAlert = true
                        }, label: {
                            Text("Delete All")
                                .foregroundColor(.red)
                        })
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !workouts.isEmpty {
                        Button(action: {
                            withAnimation {
                                isEditing.toggle()
                            }
                        }, label: {
                            Text(isEditing ? "Done" : "Edit")
                        })
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
