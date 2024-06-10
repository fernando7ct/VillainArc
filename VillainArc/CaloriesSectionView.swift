import SwiftUI
import SwiftData

struct CaloriesSectionView: View {
    @Environment(\.modelContext) private var context
    @State private var healthActiveEnergy: [HealthActiveEnergy] = []
    @State private var healthRestingEnergy: [HealthRestingEnergy] = []
    
    func getHealthActiveEnergy() {
        HealthManager.shared.fetchActiveEnergy(context: context)
        
        let fetchDescriptor = FetchDescriptor<HealthActiveEnergy>(
            sortBy: [SortDescriptor(\HealthActiveEnergy.date, order: .reverse)]
        )
        do {
            healthActiveEnergy = try context.fetch(fetchDescriptor)
        } catch {
            
        }
    }
    func getHealthRestingEnergy() {
        HealthManager.shared.fetchRestingEnergy(context: context)
        
        let fetchDescriptor = FetchDescriptor<HealthRestingEnergy>(
            sortBy: [SortDescriptor(\HealthRestingEnergy.date, order: .reverse)]
        )
        do {
            healthRestingEnergy = try context.fetch(fetchDescriptor)
        } catch {
            
        }
    }
    
    var body: some View {
        HStack {
            NavigationLink(destination: CaloriesView()) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Calories")
                        .foregroundStyle(Color.secondary)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    if let activeCalories = healthActiveEnergy.first, let restingCalories = healthRestingEnergy.first {
                        let total = activeCalories.activeEnergy + restingCalories.restingEnergy
                        Text("\(Int(total))")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                    }
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
        .onAppear {
            getHealthActiveEnergy()
            getHealthRestingEnergy()
        }
        .customStyle()
    }
}

#Preview {
    CaloriesSectionView()
}
