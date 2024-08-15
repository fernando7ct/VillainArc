import SwiftUI

struct NutritionTab: View {
    @Environment(\.modelContext) private var context
    @AppStorage("nutritionSetup") var nutritionSetup = false
    @Binding var path: NavigationPath
    @Binding var date: Date
    
    var body: some View {
        if nutritionSetup {
            NutritionEntryView(date: $date, path: $path)
                .onAppear {
                    DataManager.shared.nutritionEntryToday(context: context) { madeAlready in
                        if !madeAlready {
                            DataManager.shared.createNutritionEntry(context: context)
                            date = .now.startOfDay
                        }
                    }
                }
        } else {
            NutritionSetupView()
        }
    }
}

#Preview {
    NutritionTab(path: .constant(.init()), date: .constant(.now))
}
