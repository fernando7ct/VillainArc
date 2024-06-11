import SwiftUI
import SwiftData

struct WorkoutSectionView: View {
    @Query(filter: #Predicate<Workout> { workout in
        !workout.template
    }, sort: \Workout.startTime, order: .reverse) private var workouts: [Workout]
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
                }, label: {
                    Label("New Workout", systemImage: "plus")
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
                ForEach(workouts.prefix(3)) { workout in
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
                        .customStyle()
                    }
                }
            }
            if workouts.count > 3 {
                NavigationLink(destination: AllWorkoutsView()) {
                    HStack {
                        Text("View All Workouts")
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
