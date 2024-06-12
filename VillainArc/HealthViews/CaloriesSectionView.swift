import SwiftUI
import SwiftData

struct CaloriesSectionView: View {
    var activeCalories: Double
    var restingCalories: Double
        
    var body: some View {
        HStack {
            NavigationLink(destination: CaloriesView()) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("\(Int(activeCalories))")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                        Text("Active")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.secondary)
                            .font(.title2)
                            .padding(.bottom, 3)
                    }
                    Spacer()
                    HStack(alignment: .bottom, spacing: 4) {
                        let totalCalories = activeCalories + restingCalories
                        Text("\(Int(totalCalories))")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                        Text("Total")
                            .fontWeight(.semibold)
                            .font(.title2)
                            .foregroundStyle(Color.secondary)
                            .padding(.bottom, 3)
                    }
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("Calories Burned")
                        .foregroundStyle(Color.secondary)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.bottom, 5)
                }
            }
        }
        .customStyle()
    }
}
#Preview {
    CaloriesSectionView(activeCalories: 200, restingCalories: 1200)
}
