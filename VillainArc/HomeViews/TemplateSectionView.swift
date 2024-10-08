import SwiftUI
import SwiftData

struct TemplateSectionView: View {
    @Query(filter: #Predicate<Workout> { $0.template }, sort: \Workout.startTime, order: .reverse, animation: .smooth) private var templates: [Workout]
    @Environment(\.modelContext) private var context
    @State private var creatingTemplate = false
    @State private var existingWorkout: Workout? = nil
    
    private func deleteTemplate(_ template: Workout) {
        withAnimation {
            DataManager.shared.deleteWorkout(workout: template, context: context)
            HapticManager.instance.notification(type: .success)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                NavigationLink(value: 0) {
                    HStack(spacing: 3) {
                        Text("Templates")
                            .font(.title2)
                        Image(systemName: "chevron.right")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .fontWeight(.semibold)
                }
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
                }
                .hSpacing(.leading)
                .customStyle()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(templates.prefix(10)) { template in
                            WorkoutHomeRow(workout: template)
                                .contextMenu {
                                    Button {
                                        existingWorkout = template
                                    } label: {
                                        Label("Use", systemImage: "figure.strengthtraining.traditional")
                                    }
                                    Button(role: .destructive) {
                                        deleteTemplate(template)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .scrollTransition { content, phase in
                                    content
                                        .opacity(phase.isIdentity ? 1.0 : 0.1)
                                        .scaleEffect(phase.isIdentity ? 1.0 : 0.5)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 3)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .fullScreenCover(item: $existingWorkout) {
                    WorkoutView(existingWorkout: $0)
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    TemplateSectionView()
        .tint(.primary)
}
