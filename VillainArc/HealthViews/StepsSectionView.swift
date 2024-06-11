import SwiftUI
import SwiftData

struct StepsSectionView: View {
    var todaysSteps: Double
    
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
