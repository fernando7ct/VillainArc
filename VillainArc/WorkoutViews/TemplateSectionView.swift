import SwiftUI
import SwiftData

struct TemplateSectionView: View {
    @Query(sort: \Workout.startTime, order: .reverse) private var workouts: [Workout]
    @State private var creatingTemplate = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Templates")
                    .fontWeight(.semibold)
                    .font(.title2)
                Spacer()
                Button(action: {
                    creatingTemplate.toggle()
                }, label: {
                    Label("New Template", systemImage: "plus")
                })
                .fullScreenCover(isPresented: $creatingTemplate) {
                    TemplateView()
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 5)
            if workouts.filter({ $0.template }).isEmpty {
                HStack {
                    Text("You have no templates")
                    Spacer()
                }
                .customStyle()
            } else {
                ForEach(workouts.filter { $0.template }.prefix(5), id: \.self) { workout in
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
                        }
                        .customStyle()
                    }
                }
            }
            if workouts.filter({ $0.template }).count > 5 {
                NavigationLink(destination: AllTemplatesView()) {
                    HStack {
                        Text("View All Templates")
                        Spacer()
                    }
                    .customStyle()
                }
            }
        }
        .padding(.horizontal)
    }
}
