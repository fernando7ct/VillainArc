import SwiftUI

struct NutritionTab: View {
    @Environment(\.modelContext) private var context
    @AppStorage("nutritionSetup") var nutritionSetup = false
    
    var body: some View {
        if nutritionSetup {
            NutritionEntryView()
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

#Preview {
    NutritionTab()
}
