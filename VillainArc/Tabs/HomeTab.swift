import SwiftUI

struct HomeTab: View {
    @Environment(\.modelContext) private var context
    @Binding var path: NavigationPath
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                BackgroundView()
                ScrollView {
                    VStack(spacing: 0) {
                        GymSectionView()
                            .padding(.vertical)
                            .scrollTransition { content, phase in
                                content
                                    .opacity(phase.isIdentity ? 1.0 : 0.1)
                            }
                        TemplateSectionView()
                            .padding(.vertical)
                            .scrollTransition { content, phase in
                                content
                                    .opacity(phase.isIdentity ? 1.0 : 0.1)
                            }
                        WorkoutSectionView()
                            .padding(.vertical)
                            .scrollTransition { content, phase in
                                content
                                    .opacity(phase.isIdentity ? 1.0 : 0.1)
                            }
                        ExercisesSectionView()
                            .padding(.vertical)
                            .scrollTransition { content, phase in
                                content
                                    .opacity(phase.isIdentity ? 1.0 : 0.1)
                            }
                    }
                }
            }
            .navigationDestination(for: Int.self) { int in
                if int == 0 {
                    AllTemplatesView()
                } else if int == 1 {
                    AllWorkoutsView()
                } else if int == 2 {
                    AllExercisesView()
                } else if int == 3 {
                    GymSelectionView()
                }
            }
            .navigationDestination(for: Workout.self) {
                WorkoutDetailView(workout: $0)
            }
            .navigationTitle(Tab.home.rawValue)
        }
    }
}
