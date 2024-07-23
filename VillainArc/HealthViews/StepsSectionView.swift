import SwiftUI
import SwiftData

struct StepsSectionView: View {
    var todaysSteps: Double
    var todaysDistance: Double
    
    var body: some View {
        HStack {
            NavigationLink(value: 1) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .bottom, spacing: 2) {
                        Text(formattedDouble(todaysDistance))
                            .font(.title2)
                        Text("MILES")
                            .font(.subheadline)
                            .padding(.bottom, 2)
                    }
                    .foregroundStyle(Color.secondary)
                    .padding(.top, 4)
                    Text("\(Int(todaysSteps))")
                        .font(.largeTitle)
                }
                .fontWeight(.semibold)
                Spacer()
                VStack(alignment: .trailing) {
                    Image(systemName: "figure.walk")
                        .font(.title2)
                        .padding(.bottom)
                    Text("Steps")
                        .foregroundStyle(Color.secondary)
                        .font(.subheadline)
                }
                .fontWeight(.semibold)
            }
        }
        .customStyle()
    }
}

#Preview {
    StepsSectionView(todaysSteps: 9230, todaysDistance: 2.1)
}
