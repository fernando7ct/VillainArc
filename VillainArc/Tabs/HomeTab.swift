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
                        TemplateSectionView()
                            .padding(.vertical)
                        WorkoutSectionView()
                            .padding(.vertical)
                        ExercisesSectionView()
                            .padding(.vertical)
                    }
                }
            }
            .navigationTitle(Tab.home.rawValue)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        DataManager.shared.deleteDataAndSignOut(context: context)
                    } label: {
                        Text("Log Out")
                    }
                }
            }
        }
    }
}
