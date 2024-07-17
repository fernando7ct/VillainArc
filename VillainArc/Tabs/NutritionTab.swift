import SwiftUI

struct NutritionTab: View {
    @Environment(\.modelContext) private var context
    @AppStorage("nutritionSetup") var nutritionSetup = false
    @Binding var path: NavigationPath
    
    var body: some View {
        if nutritionSetup {
            NutritionEntryView(path: $path)
                .onAppear {
                    DataManager.shared.nutritionEntryToday(context: context) { madeAlready in
                        if !madeAlready {
                            DataManager.shared.createNutritionEntry(context: context)
                        }
                    }
                }
        } else {
            NutritionSetupView()
        }
    }
}
