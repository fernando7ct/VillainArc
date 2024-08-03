import SwiftUI
import Charts

struct Items: Identifiable {
    var id: UUID
    var date: Date
    var value: Double
    
    init(date: Date, value: Double) {
        self.id = UUID()
        self.date = date
        self.value = value
    }
    
    static func TestItems() -> [Items] {
        return [
            .init(date: Date.from(7, 30, 2024), value: 155),
            .init(date: Date.from(7, 29, 2024), value: 150),
            .init(date: Date.from(7, 28, 2024), value: 155),
            .init(date: Date.from(7, 23, 2024), value: 150),
        ]
    }
}

struct Testing: View {
    @State private var items = Items.TestItems()
    @State private var selectedRange: GraphRanges = .week
    
    func xAxisRange() -> ClosedRange<Date> {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .day, value: -7, to: Date.now.startOfDay)!
        
        return start...Date.now
    }
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Current Weight")
                        .foregroundStyle(.secondary)
                        .textScale(.secondary)
                    Text("152.2 lbs")
                        .font(.title)
                    
                }
                .fontWeight(.semibold)
            }
            .hSpacing(.leading)
            .padding(.bottom)
            
            Chart {
                ForEach(items) { item in
                    AreaMark(x: .value("Date", item.date), yStart: .value("Value", 0), yEnd: .value("Value", item.value))
                        .foregroundStyle(Color.blue.gradient.opacity(0.3))
                }
            }
            .chartXScale(domain: xAxisRange())
            .chartXAxis {}
            .frame(height: 150)
            
            
            HStack {
                Text(xAxisRange().lowerBound, format: .dateTime.month(.abbreviated).day().year())
                Spacer()
                Text("Today")
            }
            .padding(.trailing, 30)
            .textScale(.secondary)
            .foregroundStyle(.secondary)
            
            Picker("Time Range", selection: $selectedRange) {
                Text("W").tag(GraphRanges.week)
                Text("M").tag(GraphRanges.month)
                Text("6M").tag(GraphRanges.sixMonths)
                Text("Y").tag(GraphRanges.year)
                Text("All").tag(GraphRanges.all)
            }
            .pickerStyle(.segmented)
            .padding(.top)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        }
        .padding(.horizontal)
        .navigationTitle("Weight")
        .navigationBarTitleDisplayMode(.large)
        .vSpacing(.top)
        
    }
}

#Preview {
    NavigationView {
        Testing()
    }
}
