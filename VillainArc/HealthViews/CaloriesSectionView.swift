import SwiftUI
import SwiftData

struct CaloriesSectionView: View {
    @Environment(\.modelContext) private var context
    @Binding var activeCalories: Double
    @Binding var restingCalories: Double
        
    var body: some View {
        HStack {
            NavigationLink(destination: CaloriesView()) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Calories Burned")
                        .foregroundStyle(Color.secondary)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    let totalCalories = activeCalories + restingCalories
                    Text("\(Int(totalCalories))")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                }
                Spacer()
                VStack {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
        }
        .customStyle()
    }
}
