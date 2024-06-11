import SwiftUI
import SwiftData

struct TemplateSectionView: View {
    @Query(filter: #Predicate<Workout> { workout in
        workout.template
    }, sort: \Workout.startTime, order: .reverse) private var templates: [Workout]
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
            if templates.isEmpty {
                HStack {
                    Text("You have no templates")
                    Spacer()
                }
                .customStyle()
            } else {
                ForEach(templates.prefix(5)) { template in
                    NavigationLink(destination: WorkoutDetailView(workout: template)) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(template.title)
                                    .fontWeight(.semibold)
                                Text(concatenatedExerciseNames(for: template))
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
            if templates.count > 5 {
                NavigationLink(destination: AllTemplatesView()) {
                    HStack {
                        Text("View All Templates")
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
