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
                            .padding(.bottom)
                            .scrollTransition { content, phase in
                                content
                                    .blur(radius: phase.isIdentity ? 0 : 1.5)
                                    .opacity(phase.isIdentity ? 1 : 0.7)
                            }
                        TemplateSectionView()
                            .padding(.vertical)
                            .scrollTransition { content, phase in
                                content
                                    .blur(radius: phase.isIdentity ? 0 : 1.5)
                                    .opacity(phase.isIdentity ? 1 : 0.7)
                            }
                        WorkoutSectionView()
                            .padding(.vertical)
                            .scrollTransition { content, phase in
                                content
                                    .blur(radius: phase.isIdentity ? 0 : 1.5)
                                    .opacity(phase.isIdentity ? 1 : 0.7)
                            }
                        ExercisesSectionView()
                            .padding(.vertical)
                            .scrollTransition { content, phase in
                                content
                                    .blur(radius: phase.isIdentity ? 0 : 1.5)
                                    .opacity(phase.isIdentity ? 1 : 0.7)
                            }
                    }
                }
                .vSpacing(.top)
                .scrollIndicators(.hidden)
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
            .safeAreaInset(edge: .top) {
                HStack {
                    Text(Tab.home.rawValue)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding()
            }
        }
    }
}
