import SwiftUI
import SwiftData

struct WeightSectionView: View {
    @Query(sort: \WeightEntry.date, order: .reverse, animation: .smooth) private var entries: [WeightEntry]
    
    private func latestDate() -> String {
        if let mostRecent = entries.first {
            let calendar = Calendar.current
            let mostRecentDate = calendar.startOfDay(for: mostRecent.date)
            let today = calendar.startOfDay(for: Date())
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)
            if mostRecentDate == today {
                return "Today"
            } else if mostRecentDate == yesterday {
                return "Yesterday"
            } else {
                return mostRecentDate.formatted(.dateTime.month().day().year())
            }
        }
        return " "
    }
    
    private func latestWeight() -> Double {
        if let mostRecent = entries.first {
            return mostRecent.weight
        } else {
            return 0
        }
    }
    
    var body: some View {
        HStack {
            NavigationLink(value: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(latestDate())
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                        .padding(.top, 4)
                    HStack(alignment: .bottom, spacing: 4) {
                        Text(formattedDouble(latestWeight()))
                            .font(.largeTitle)
                        if latestWeight() != 0 {
                            Text("lbs")
                                .font(.title2)
                                .foregroundStyle(Color.secondary)
                                .padding(.bottom, 3)
                        }
                    }
                }
                .fontWeight(.semibold)
                Spacer()
                VStack(alignment: .trailing) {
                    Image(systemName: "scalemass.fill")
                        .font(.title2)
                        .padding(.bottom)
                    Text("Weight")
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
    WeightSectionView()
}
