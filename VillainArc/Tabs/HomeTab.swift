import SwiftUI

struct HomeTab: View {
    @Environment(\.modelContext) private var context
    
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

#Preview {
    HomeTab()
}
