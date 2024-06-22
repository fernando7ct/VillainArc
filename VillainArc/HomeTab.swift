import SwiftUI

struct HomeTab: View {
    
    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView()
                ScrollView {
                    VStack(spacing: 0) {
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
        }
    }
}

#Preview {
    HomeTab()
}
