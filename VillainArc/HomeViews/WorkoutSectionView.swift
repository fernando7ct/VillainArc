import SwiftUI
import SwiftData

struct WorkoutSectionView: View {
    @Query(filter: #Predicate<Workout> { workout in
        !workout.template
    }, sort: \Workout.startTime, order: .reverse, animation: .smooth) private var workouts: [Workout]
    @Environment(\.modelContext) private var context
    @State private var workoutStarted = false
    @State private var existingWorkout: Workout? = nil
    
    private func deleteWorkout(_ workout: Workout) {
        withAnimation {
            DataManager.shared.deleteWorkout(workout: workout, context: context)
            HapticManager.instance.notification(type: .success)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Past Workouts")
                    .fontWeight(.semibold)
                    .font(.title2)
                Spacer()
                Button(action: {
                    workoutStarted.toggle()
                    HapticManager.instance.impact(style: .heavy)
                }, label: {
                    Label("New Workout", systemImage: "plus")
                        .fontWeight(.medium)
                })
                .fullScreenCover(isPresented: $workoutStarted) {
                    WorkoutView()
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 5)
            
            if workouts.isEmpty {
                HStack {
                    Text("You have no past workouts")
                    Spacer()
                }
                .customStyle()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(workouts.prefix(3)) { workout in
                            WorkoutHomeRow(workout: workout)
                                .contextMenu {
                                    Button {
                                        existingWorkout = workout
                                    } label: {
                                        Label("Use", systemImage: "figure.strengthtraining.traditional")
                                    }
                                    Button(role: .destructive) {
                                        deleteWorkout(workout)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .scrollTransition { content, phase in
                                    content
                                        .opacity(phase.isIdentity ? 1.0 : 0.1)
                                        .scaleEffect(phase.isIdentity ? 1.0 : 0.5)
                                }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .fullScreenCover(item: $existingWorkout) { workout in
                    WorkoutView(existingWorkout: workout)
                }
            }
            if workouts.count > 2 {
                NavigationLink(value: 1) {
                    HStack {
                        Text("All Workouts")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .customStyle()
                }
            }
            
        }
        .padding(.horizontal)
    }
}
#Preview {
    WorkoutSectionView()
}

struct WorkoutHomeRow: View {
    @State var workout: Workout
    
    var body: some View {
        NavigationLink(value: workout) {
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 0) {
                            Text(workout.title)
                            if !workout.template {
                                Text("\(workout.startTime.formatted(.dateTime.month().day().year()))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text(exerciseCategories(for: workout))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .fontWeight(.semibold)
                    }
                    Spacer()
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(workout.exercises.sorted(by: { $0.order < $1.order}).prefix(5)) { exercise in
                                HStack(spacing: 1) {
                                    Text("\(exercise.sets.count)x")
                                    Text(exercise.name)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                .lineLimit(1)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.vertical, 1)
                            }
                        }
                        if workout.exercises.count > 5 {
                            let remaining = workout.exercises.count - 5
                            HStack(spacing: 2) {
                                Image(systemName: "plus")
                                    .font(.subheadline)
                                Text("\(remaining)")
                                    .font(.headline)
                                Text("More")
                                    .font(.headline)
                            }
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.secondary)
                        }
                    }
                }
            }
            .frame(width: 330, height: 130)
            .padding()
            .background(.ultraThinMaterial, in: .rect(cornerRadius: 12))
            .padding(.horizontal)
            .padding(.vertical, 3)
        }
    }
}
