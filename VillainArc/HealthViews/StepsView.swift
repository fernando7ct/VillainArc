import SwiftUI
import Charts
import SwiftData

struct StepsView: View {
    @Query(sort: \HealthSteps.date, order: .reverse) private var healthSteps: [HealthSteps]
    @State private var selectedStepRange: GraphRanges = .week
    @State private var selectedEntry: (date: Date, steps: Double)? = nil
    
    private func yAxisRange() -> ClosedRange<Double> {
        let filteredEntries = filteredEntries()
        guard let maxSteps = filteredEntries.map({ $0.steps }).max() else {
            return 0...10000
        }
        return 0...(maxSteps + 1000)
    }
    
    private func xAxisRange() -> ClosedRange<Date> {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let (startDate, endDate): (Date, Date) = {
            switch selectedStepRange {
            case .week:
                let start = calendar.date(byAdding: .day, value: -6, to: today)!
                let end = calendar.date(byAdding: .day, value: 1, to: today)!
                return (start, end)
            case .month:
                let start = calendar.date(byAdding: .day, value: -28, to: today)!
                let end = calendar.date(byAdding: .day, value: 4, to: today)!
                return (start, end)
            case .sixMonths:
                let startOfPrevious5thMonth = calendar.date(byAdding: .month, value: -5, to: calendar.date(from: calendar.dateComponents([.year, .month], from: today))!)!
                let endOfCurrentMonth = calendar.date(byAdding: .month, value: 1, to: calendar.date(from: calendar.dateComponents([.year, .month], from: today))!)!
                return (startOfPrevious5thMonth, endOfCurrentMonth)
            }
        }()
        return startDate...endDate
    }
    
    private func filteredEntries() -> [HealthSteps] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let (startDate, endDate): (Date, Date) = {
            switch selectedStepRange {
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
        
        return healthSteps.filter { $0.date >= startDate && $0.date < endDate }
    }
    
    private func graphableEntries() -> [(date: Date, steps: Double)] {
        let calendar = Calendar.current
        let entries = filteredEntries()
        var averages: [(date: Date, steps: Double)] = []
        
        if selectedStepRange == .sixMonths {
            let groupedByWeek = Dictionary(grouping: entries, by: { calendar.dateInterval(of: .weekOfYear, for: $0.date)!.start })
            for (startOfWeek, entries) in groupedByWeek {
                let totalSteps = entries.reduce(0) { $0 + $1.steps }
                let averageWeight = totalSteps / Double(entries.count)
                averages.append((date: startOfWeek, steps: averageWeight))
            }
        } else {
            let groupedByDay = Dictionary(grouping: entries, by: { calendar.startOfDay(for: $0.date) })
            for (date, entries) in groupedByDay {
                let totalSteps = entries.reduce(0) { $0 + $1.steps }
                let averageWeight = totalSteps / Double(entries.count)
                let startOfDay = calendar.startOfDay(for: date)
                averages.append((date: startOfDay, steps: averageWeight))
            }
        }
        
        return averages.sorted { $0.date < $1.date }
    }
    
    private func stepsData() -> (String, String, String) {
        let calendar = Calendar.current
        let entries = filteredEntries()
        let today = calendar.startOfDay(for: Date())
        
        var average: String
        var averageSteps: String
        var timeRange: String
        
        if entries.isEmpty {
            average = ""
            averageSteps = "No Data"
        } else if entries.count == 1 {
            average = ""
            averageSteps = "\(Int(entries.first!.steps))"
        } else {
            average = "Average"
            let average = entries.map { $0.steps }.reduce(0, +) / Double(entries.count)
            averageSteps = "\(Int(average))"
        }
        
        switch selectedStepRange {
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
        
        return (average, averageSteps, timeRange)
    }
    
    var body: some View {
        ZStack {
            BackgroundView()
            VStack {
                Picker("Time Range", selection: $selectedStepRange) {
                    Text("Week").tag(GraphRanges.week)
                    Text("Month").tag(GraphRanges.month)
                    Text("6 Months").tag(GraphRanges.sixMonths)
                }
                .pickerStyle(.segmented)
                .padding(.top)
                HStack {
                    VStack(alignment: .leading) {
                        let (averageText, steps, range) = stepsData()
                        Text(averageText)
                            .foregroundStyle(.secondary)
                            .font(.headline)
                        HStack(alignment: .bottom, spacing: 3) {
                            Text(steps)
                                .foregroundStyle(.primary)
                                .font(.largeTitle)
                            if steps != "No Data" {
                                Text("Steps")
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
                Chart(graphableEntries(), id: \.date) { healthStep in
                    if graphableEntries().count == 1 {
                        PointMark(x: .value("Date", healthStep.date), y: .value("Steps", healthStep.steps))
                            .foregroundStyle(Color.primary)
                    }
                    LineMark(
                        x: .value("Date", healthStep.date),
                        y: .value("Steps", healthStep.steps)
                    )
                    .foregroundStyle(Color.primary)
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                    AreaMark(
                        x: .value("Date", healthStep.date),
                        yStart: .value("Steps", yAxisRange().lowerBound),
                        yEnd: .value("Steps", healthStep.steps)
                    )
                    .foregroundStyle(Color.primary.opacity(0.6))
                    .interpolationMethod(.monotone)
                    if let selectedEntry {
                        RuleMark(
                            x: .value("Date", selectedEntry.date)
                        )
                        .foregroundStyle(Color.primary)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Steps")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(Int(selectedEntry.steps))")
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
                    if selectedStepRange == .week {
                        AxisMarks(values: .automatic(desiredCount: 7)) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        }
                    } else if selectedStepRange == .month {
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
                                            
                                            switch selectedStepRange {
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
                .padding(.vertical)
                .frame(maxHeight: 400)
                Spacer()
            }
            .padding(.horizontal)
            .navigationTitle("Steps")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    StepsView()
}
