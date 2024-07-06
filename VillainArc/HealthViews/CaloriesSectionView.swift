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
                        Text("Active")
                            .foregroundStyle(Color.secondary)
                            .font(.title2)
                            .padding(.bottom, 3)
                    }
                    Spacer()
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("\(Int(activeCalories + restingCalories))")
                            .font(.largeTitle)
                        Text("Total")
                            .font(.title2)
                            .foregroundStyle(Color.secondary)
                            .padding(.bottom, 3)
                    }
                }
                .fontWeight(.semibold)
                Spacer()
                VStack(alignment: .trailing) {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                    Spacer()
                    Text("Calories Burned")
                        .foregroundStyle(Color.secondary)
                        .font(.subheadline)
                        .padding(.bottom, 5)
                }
                .fontWeight(.semibold)
            }
        }
        .customStyle()
    }
}
#Preview {
    CaloriesSectionView(activeCalories: 200, restingCalories: 1200)
}
