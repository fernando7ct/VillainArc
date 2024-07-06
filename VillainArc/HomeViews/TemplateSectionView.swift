import SwiftUI
import SwiftData

struct TemplateSectionView: View {
    @Query(filter: #Predicate<Workout> { workout in
        workout.template
    }, sort: \Workout.startTime, order: .reverse, animation: .smooth) private var templates: [Workout]
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
                    HapticManager.instance.impact(style: .heavy)
                }, label: {
                    Label("New Template", systemImage: "plus")
                        .fontWeight(.medium)
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
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(templates.prefix(5)) { template in
                            WorkoutHomeRow(workout: template, deleteOn: true)
                        }
                    }
                }
            }
            if templates.count > 2 {
                NavigationLink(destination: AllTemplatesView()) {
                    HStack {
                        Text("All Templates")
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
