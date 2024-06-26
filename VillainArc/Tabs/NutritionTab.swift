import SwiftUI

struct NutritionTab: View {
    @Environment(\.modelContext) private var context
    @AppStorage("nutritionSetup") var nutritionSetup = false
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    
    var body: some View {
        if nutritionSetup {
            NutritionEntryView(date: $selectedDate)
                .onAppear {
                    DataManager.shared.nutritionEntryToday(context: context) { madeAlready in
                        if !madeAlready {
                            DataManager.shared.createNutritionEntry(context: context)
                        }
                    }
                    selectedDate = Calendar.current.startOfDay(for: Date())
                }
        } else {
            NutritionSetupView()
        }
    }
}

#Preview {
    NutritionTab()
}
