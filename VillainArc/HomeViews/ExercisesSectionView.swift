import SwiftUI
import SwiftData

struct ExercisesSectionView: View {
    @Query(filter: #Predicate<Workout> { workout in
        !workout.template
    }) private var workouts: [Workout]
    
    private var topExercises: [ExerciseInfo] {
        var exerciseDict: [String: ExerciseInfo] = [:]
        for workout in workouts {
            for exercise in workout.exercises {
                if exerciseDict[exercise.name] == nil {
                    exerciseDict[exercise.name] = ExerciseInfo(name: exercise.name, category: exercise.category, count: 0, sets: [])
                }
                exerciseDict[exercise.name]?.count += 1
                exerciseDict[exercise.name]?.sets.append(contentsOf: exercise.sets)
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
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Top Exercises")
                    .fontWeight(.semibold)
                    .font(.title2)
            }
            .hSpacing(.leading)
            .padding(.horizontal)
            .padding(.bottom, 5)
            
            if topExercises.isEmpty {
                HStack {
                    Text("You haven't done any exercises")
                }
                .hSpacing(.leading)
                .customStyle()
            } else {
                ForEach(topExercises, id: \.name) { item in
                    ExerciseRow(item: item)
                        .customStyle()
                }
            }
            if workouts.flatMap({ $0.exercises }).count > 5 {
                NavigationLink(value: 2) {
                    HStack {
                        Text("All Exercises")
                            .fontWeight(.semibold)
                    }
                    .hSpacing(.leading)
                    .customStyle()
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    ExercisesSectionView()
}
