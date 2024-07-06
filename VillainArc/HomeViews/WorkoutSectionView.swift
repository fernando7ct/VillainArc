import SwiftUI
import SwiftData

struct WorkoutSectionView: View {
    @Query(filter: #Predicate<Workout> { workout in
        !workout.template
    }, sort: \Workout.startTime, order: .reverse, animation: .smooth) private var workouts: [Workout]
    @State private var workoutStarted = false
    
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
                            WorkoutHomeRow(workout: workout, deleteOn: true)
                        }
                    }
                }
            }
            if workouts.count > 2 {
                NavigationLink(destination: AllWorkoutsView()) {
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
    @State var deleteOn: Bool
    
    var body: some View {
        NavigationLink(destination: WorkoutDetailView(workout: workout, deleteOn: deleteOn)) {
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 0) {
                            Text(workout.title)
                            if !workout.template {
                                Text("\(workout.startTime.formatted(.dateTime.month().day().year()))")
                                    .font(.caption2)
                                    .foregroundStyle(Color.secondary)
                            } else {
                                Text(exerciseCategories(for: workout))
                                    .font(.caption2)
                                    .foregroundStyle(Color.secondary)
                            }
                        }
                        .fontWeight(.semibold)
                    }
                    Spacer()
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(workout.exercises!.sorted(by: { $0.order < $1.order}).prefix(5)) { exercise in
                                HStack(spacing: 1) {
                                    Text("\(exercise.sets!.count)x")
                                        .foregroundStyle(Color.primary)
                                    Text(exercise.name)
                                        .foregroundStyle(Color.secondary)
                                    Spacer()
                                }
                                .lineLimit(1)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.vertical, 1)
                            }
                        }
                        if workout.exercises!.count > 5 {
                            let remaining = workout.exercises!.count - 5
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
