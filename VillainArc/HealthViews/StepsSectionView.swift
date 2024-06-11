import SwiftUI
import SwiftData

struct StepsSectionView: View {
    @Environment(\.modelContext) private var context
    @Binding var todaysSteps: Double
    
    var body: some View {
        HStack {
            NavigationLink(destination: StepsView()) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Steps")
                        .foregroundStyle(Color.secondary)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("\(Int(todaysSteps))")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .contentTransition(.numericText(value: todaysSteps))
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
        .customStyle()
    }
}
