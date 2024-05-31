import SwiftUI
import SwiftData
import Charts

struct WeightGraphView: View {
    @Query(sort: \WeightEntry.date, order: .reverse) private var weightEntries: [WeightEntry]
    @State private var selectedWeightRange: weightGraphRange = .week
    @State private var selectedEntry: (date: Date, weight: Double)? = nil
    
    enum weightGraphRange {
        case week
        case month
        case sixMonths
    }
    
    private func yAxisRange() -> ClosedRange<Double> {
        let filteredEntries = filteredEntries()
        guard let minWeight = filteredEntries.map({ $0.weight }).min(),
              let maxWeight = filteredEntries.map({ $0.weight }).max() else {
            return 0...100
        }
        return (minWeight < 10 ? 0 : minWeight - 10)...(maxWeight + 10)
    }
    
    private func xAxisRange() -> ClosedRange<Date> {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let (startDate, endDate): (Date, Date) = {
            switch selectedWeightRange {
            case .week:
                let start = calendar.date(byAdding: .day, value: -6, to: today)!
                let end = calendar.date(byAdding: .day, value: 1, to: today)!
                return (start, end)
            case .month:
                let start = calendar.date(byAdding: .day, value: -28, to: today)!
                let end = calendar.date(byAdding: .day, value: 7, to: today)!
                return (start, end)
            case .sixMonths:
                let startOfPrevious5thMonth = calendar.date(byAdding: .month, value: -5, to: calendar.date(from: calendar.dateComponents([.year, .month], from: today))!)!
                let endOfCurrentMonth = calendar.date(byAdding: .month, value: 1, to: calendar.date(from: calendar.dateComponents([.year, .month], from: today))!)!
                return (startOfPrevious5thMonth, endOfCurrentMonth)
            }
        }()
        return startDate...endDate
    }
    
    private func filteredEntries() -> [WeightEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let (startDate, endDate): (Date, Date) = {
            switch selectedWeightRange {
            case .week:
                let start = calendar.date(byAdding: .day, value: -6, to: today)!
                let end = calendar.date(byAdding: .day, value: 1, to: today)!
                return (start, end)
            case .month:
                let start = calendar.date(byAdding: .day, value: -28, to: today)!
                let end = calendar.date(byAdding: .day, value: 1, to: today)!
                return (start, end)
            case .sixMonths:
                let start = calendar.date(byAdding: .month, value: -5, to: calendar.date(from: calendar.dateComponents([.year, .month], from: today))!)!
                let end = calendar.date(byAdding: .month, value: 1, to: calendar.date(from: calendar.dateComponents([.year, .month], from: today))!)!
                return (start, end)
            }
        }()
        
        return weightEntries.filter { $0.date >= startDate && $0.date < endDate }
    }
    
    private func graphableEntries() -> [(date: Date, weight: Double)] {
        let calendar = Calendar.current
        let entries = filteredEntries()
        var averages: [(date: Date, weight: Double)] = []
        
        if selectedWeightRange == .sixMonths {
            let groupedByWeek = Dictionary(grouping: entries, by: { calendar.dateInterval(of: .weekOfYear, for: $0.date)!.start })
            for (startOfWeek, entries) in groupedByWeek {
                let totalWeight = entries.reduce(0) { $0 + $1.weight }
                let averageWeight = totalWeight / Double(entries.count)
                averages.append((date: startOfWeek, weight: averageWeight))
            }
        } else {
            let groupedByDay = Dictionary(grouping: entries, by: { calendar.startOfDay(for: $0.date) })
            for (date, entries) in groupedByDay {
                let totalWeight = entries.reduce(0) { $0 + $1.weight }
                let averageWeight = totalWeight / Double(entries.count)
                let startOfDay = calendar.startOfDay(for: date)
                averages.append((date: startOfDay, weight: averageWeight))
            }
        }
        
        return averages.sorted { $0.date < $1.date }
    }
    
    private func weightData() -> (String, String, String) {
        let calendar = Calendar.current
        let entries = filteredEntries()
        let today = calendar.startOfDay(for: Date())
        
        var average: String
        var averageWeight: String
        var timeRange: String
        
        if entries.isEmpty {
            average = ""
            averageWeight = "No Data"
        } else if entries.count == 1 {
            average = ""
            averageWeight = formattedWeight(entries.first!.weight)
        } else {
            average = "Average"
            let average = entries.map { $0.weight }.reduce(0, +) / Double(entries.count)
            averageWeight = formattedWeight(average)
        }
        
        switch selectedWeightRange {
        case .week:
            let start = calendar.date(byAdding: .day, value: -6, to: today)!
            timeRange = "\(start.formatted(.dateTime.month().day())) - \(today.formatted(.dateTime.month().day()))"
        case .month:
            let start = calendar.date(byAdding: .day, value: -28, to: today)!
            timeRange = "\(start.formatted(.dateTime.month().day())) - \(today.formatted(.dateTime.month().day()))"
        case .sixMonths:
            let start = calendar.date(byAdding: .month, value: -5, to: calendar.date(from: calendar.dateComponents([.year, .month], from: today))!)!
            timeRange = "\(start.formatted(.dateTime.month().year())) - \(today.formatted(.dateTime.month().year()))"
        }
        
        return (average, averageWeight, timeRange)
    }
    
    var body: some View {
        VStack {
            Picker("Time Range", selection: $selectedWeightRange) {
                Text("Week").tag(weightGraphRange.week)
                Text("Month").tag(weightGraphRange.month)
                Text("6 Months").tag(weightGraphRange.sixMonths)
            }
            .pickerStyle(SegmentedPickerStyle())
    
            HStack {
                VStack(alignment: .leading) {
                    let (averageText, weight, range) = weightData()
                    Text(averageText)
                        .foregroundStyle(.secondary)
                        .font(.headline)
                    HStack(alignment: .bottom, spacing: 3) {
                        Text(weight)
                            .foregroundStyle(.primary)
                            .font(.largeTitle)
                        if weight != "No Data" {
                            Text("lbs")
                                .foregroundStyle(.secondary)
                                .offset(y: -4.0)
                        }
                    }
                    Text(range)
                        .foregroundStyle(.secondary)
                        .font(.headline)
                }
                
                Spacer()
            }
            .fontWeight(.medium)
            Chart(graphableEntries(), id: \.date) { weightEntry in
                LineMark(
                    x: .value("Date", weightEntry.date),
                    y: .value("Weight", weightEntry.weight)
                )
                .interpolationMethod(.monotone)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
                AreaMark(
                    x: .value("Date", weightEntry.date),
                    yStart: .value("Weight", yAxisRange().lowerBound),
                    yEnd: .value("Weight", weightEntry.weight)
                )
                .foregroundStyle(Color.blue.gradient.opacity(0.5))
                .interpolationMethod(.monotone)
                if let selectedEntry {
                    RuleMark(
                        x: .value("Date", selectedEntry.date)
                    )
                    .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Weight")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(formattedWeight(selectedEntry.weight)) lbs")
                                .font(.title3)
                                .bold()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color(uiColor: UIColor.secondarySystemBackground).shadow(.drop(radius: 2)))
                        }
                    }
                }
            }
            .chartYScale(domain: yAxisRange())
            .chartXScale(domain: xAxisRange())
            .chartXAxis {
                if selectedWeightRange == .week {
                    AxisMarks(values: .automatic(desiredCount: 7)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    }
                } else if selectedWeightRange == .month {
                    AxisMarks(values: .stride(by: .day, count: 7))
                } else {
                    AxisMarks(values: .stride(by: .month, count: 1)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month())
                    }
                }
            }
            .chartOverlay(content: { proxy in
                GeometryReader { innerProxy in
                    Rectangle()
                        .fill(.clear).contentShape(Rectangle())
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let location = value.location
                                    if let date: Date = proxy.value(atX: location.x) {
                                        let calendar = Calendar.current
                                        let timeComponent: Calendar.Component
                                        let entries = graphableEntries()
                                        
                                        switch selectedWeightRange {
                                        case .week, .month:
                                            timeComponent = .day
                                        case .sixMonths:
                                            timeComponent = .weekOfYear
                                        }
                                        
                                        let time = calendar.component(timeComponent, from: date)
                                        if let currentEntry = entries.first(where: { item in
                                            calendar.component(timeComponent, from: item.date) == time
                                        }) {
                                            selectedEntry = currentEntry
                                        }
                                    }
                                }.onEnded { value in
                                    selectedEntry = nil
                                }
                        )
                }
            })
        }
    }
}

#Preview {
    WeightGraphView()
}
