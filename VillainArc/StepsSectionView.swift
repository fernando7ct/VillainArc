import SwiftUI
import SwiftData

struct StepsSectionView: View {
    @Environment(\.modelContext) private var context
    @State private var healthSteps: [HealthSteps] = []
    
    func getHealthSteps() {
        HealthManager.shared.fetchSteps(context: context)
        let fetchDescriptor = FetchDescriptor<HealthSteps>(
            sortBy: [SortDescriptor(\HealthSteps.date, order: .reverse)]
        )
        do {
            healthSteps = try context.fetch(fetchDescriptor)
        } catch {
            
        }
        
    }
    
    var body: some View {
        HStack {
            NavigationLink(destination: StepsView()) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Steps")
                        .foregroundStyle(Color.secondary)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    if let steps = healthSteps.first {
                        Text("\(Int(steps.steps))")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                    }
                }
                Spacer()
                VStack {
                    Image(systemName: "figure.walk")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
        }
        .onAppear {
            getHealthSteps()
        }
        .customStyle()
    }
}

#Preview {
    StepsSectionView()
}
