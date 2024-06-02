import SwiftUI
import SwiftData

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
                    }
                }
            }
            .navigationTitle("Home")
        }
    }
}

#Preview {
    HomeTab()
}
