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
            .navigationTitle("Home")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
    }
}

#Preview {
    HomeTab()
}
