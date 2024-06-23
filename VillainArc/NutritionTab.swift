import SwiftUI

struct NutritionTab: View {
    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView()
                ScrollView {
                    
                }
            }
            .navigationTitle(Tab.nutrition.rawValue)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        }
    }
}

#Preview {
    NutritionTab()
}
