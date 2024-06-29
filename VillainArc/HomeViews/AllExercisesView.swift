import SwiftUI
import SwiftData

struct AllExercisesView: View {
    @Query(filter: #Predicate<Workout> { workout in
        !workout.template
    }) private var workouts: [Workout]

    private var topExercises: [ExerciseInfo] {
        var exerciseDict: [String: ExerciseInfo] = [:]
        for workout in workouts {
            for exercise in workout.exercises! {
                if exerciseDict[exercise.name] == nil {
                    exerciseDict[exercise.name] = ExerciseInfo(name: exercise.name, category: exercise.category, count: 0, sets: [])
                }
                exerciseDict[exercise.name]?.count += 1
                exerciseDict[exercise.name]?.sets.append(contentsOf: exercise.sets!)
            }
        }
        return exerciseDict.values
            .sorted {
                if $0.count == $1.count {
                    if $0.sets.count == $1.sets.count {
                        return $0.name > $1.name
                    }
                    return $0.sets.count > $1.sets.count
                }
                return $0.count > $1.count
            }
            .map { $0 }
    }

    var body: some View {
        ZStack {
            BackgroundView()
            List {
                ForEach(topExercises, id: \.name) { item in
                    HStack {
                        ExerciseRow(item: item)
                    }
                    .listRowBackground(BlurView())
                    .listRowSeparator(.hidden)
                }
            }
            .scrollContentBackground(.hidden)
            .overlay {
                if topExercises.isEmpty {
                    ContentUnavailableView("No exercises found.", systemImage: "dumbbell")
                }
            }
            .navigationTitle("All Exercises")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        }
    }
}
struct ExerciseRow: View {
    var item: ExerciseInfo
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(item.name)
                .fontWeight(.semibold)
                .lineLimit(1)
            Text(item.category)
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
            Text(topSet(for: item))
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
        }
        Spacer()
        VStack(alignment: .trailing, spacing: 0) {
            Text("Completed")
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
            Text("\(item.count) \(item.count == 1 ? "time" : "times")")
                .fontWeight(.semibold)
            Text("\(item.sets.count) \(item.sets.count == 1 ? "set" : "sets")")
                .fontWeight(.semibold)
        }
    }
}
#Preview {
    AllExercisesView()
}
