import SwiftUI
import SwiftData

struct StepsSectionView: View {
    @Query(sort: \HealthSteps.date, order: .reverse) private var healthSteps: [HealthSteps]
    
    var body: some View {
        HStack {
            ForEach(healthSteps.prefix(1)) { healthSteps in
                NavigationLink(destination: StepsView()) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Steps")
                            .foregroundStyle(Color.secondary)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("\(Int(healthSteps.steps))")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                    }
                    Spacer()
                    VStack {
                        Image(systemName: "figure.walk")
                            .font(.title2)
                            .foregroundStyle(.red)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
            }
        }
        .customStyle()
    }
}

#Preview {
    StepsSectionView()
}
