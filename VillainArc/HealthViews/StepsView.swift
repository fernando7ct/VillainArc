import SwiftUI
import Charts
import SwiftData

struct StepsView: View {
    @Query(sort: \HealthSteps.date, order: .reverse) private var healthSteps: [HealthSteps]
    @State private var selectedStepRange: GraphRanges = .week
    @State private var selectedEntry: (date: Date, steps: Double)? = nil
    @State private var selectedDate: Date?
    @State private var scrollPosition = Calendar.current.date(byAdding: .day, value: -6, to: Calendar.current.startOfDay(for: Date()))!
    @State private var scrollDatePosition: Date = Date()
    
    private func domainLength() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        switch selectedStepRange {
        case .week:
            let start = calendar.date(byAdding: .day, value: -6, to: today)!
            let end = calendar.date(byAdding: .day, value: 1, to: today)!
            return Int(end.timeIntervalSince(start))
        case .month:
            let start = calendar.date(byAdding: .day, value: -28, to: today)!
            let end = calendar.date(byAdding: .day, value: 7, to: today)!
            return Int(end.timeIntervalSince(start))
        case .sixMonths:
            let start = calendar.date(byAdding: .month, value: -5, to: calendar.date(from: calendar.dateComponents([.year, .month], from: today))!)!
            let end = calendar.date(byAdding: .month, value: 1, to: calendar.date(from: calendar.dateComponents([.year, .month], from: today))!)!
            return Int(end.timeIntervalSince(start))
        }
    }
    private func yAxisRange() -> ClosedRange<Double> {
        guard let maxSteps = healthSteps.map({ $0.steps }).max() else {
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
                let rangeDifference = end.timeIntervalSince(start)
                if let firstEntry = healthSteps.last {
                    let difference = end.timeIntervalSince(firstEntry.date)
                    if difference < rangeDifference {
                        return (start, end)
                    } else {
                        let remainder = Int(difference / rangeDifference)
                        let newStart = calendar.date(byAdding: .day, value: (-7 * remainder), to: start)!
                        return (newStart, end)
                    }
                }
                return (start, end)
            case .month:
                let start = calendar.date(byAdding: .day, value: -28, to: today)!
                let end = calendar.date(byAdding: .day, value: 7, to: today)!
                let rangeDifference = end.timeIntervalSince(start)
                if let firstEntry = healthSteps.last {
                    let difference = end.timeIntervalSince(firstEntry.date)
                    if difference < rangeDifference {
                        return (start, end)
                    } else {
                        let remainder = Int(difference / rangeDifference)
                        let newStart = calendar.date(byAdding: .day, value: (-35 * remainder), to: start)!
                        return (newStart, end)
                    }
                }
                return (start, end)
            case .sixMonths:
                let start = calendar.date(byAdding: .month, value: -5, to: calendar.date(from: calendar.dateComponents([.year, .month], from: today))!)!
                let end = calendar.date(byAdding: .month, value: 1, to: calendar.date(from: calendar.dateComponents([.year, .month], from: today))!)!
                let rangeDifference = end.timeIntervalSince(start)
                if let firstEntry = healthSteps.last {
                    let difference = end.timeIntervalSince(firstEntry.date)
                    if difference < rangeDifference {
                        return (start, end)
                    } else {
                        let remainder = Int(difference / rangeDifference)
                        let newStart = calendar.date(byAdding: .month, value: (-6 * remainder), to: start)!
                        return (newStart, end)
                    }
                }
                return (start, end)
            }
        }()
        return startDate...endDate
    }
    
    private func graphableEntries() -> [(date: Date, steps: Double)] {
        let calendar = Calendar.current
        let entries = healthSteps
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
    
    private func stepsData() -> (average: String, steps: String, dateRange: String) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let (startDate, endDate): (Date, Date) = {
            switch selectedStepRange {
            case .week:
                let end = calendar.date(byAdding: .day, value: 7, to: scrollDatePosition)!
                return (scrollDatePosition, end)
            case .month:
                let end = calendar.date(byAdding: .day, value: 35, to: scrollDatePosition)!
                return (scrollDatePosition, end)
            case .sixMonths:
                let end = calendar.date(byAdding: .month, value: 6, to: calendar.date(from: calendar.dateComponents([.year, .month], from: scrollDatePosition))!)!
                return (scrollDatePosition, end)
            }
        }()
        
        let entries = healthSteps.filter { $0.date >= startDate && $0.date <= endDate}
        var average: String
        var steps: String
        if entries.isEmpty {
            average = " "
            steps = "No Data"
        } else if entries.count == 1 {
            average = " "
            steps = "\(Int(entries.first!.steps))"
        } else {
            average = "Average"
            let averageSteps = entries.map { $0.steps }.reduce(0, +) / Double(entries.count)
            steps = "\(Int(averageSteps))"
        }
        
        var dateRange: String
        switch selectedStepRange {
        case .week, .month:
            if today >= startDate && today <= endDate {
                dateRange = "\(startDate.formatted(.dateTime.month().day())) - \(today.formatted(.dateTime.month().day()))"
            } else {
                dateRange = "\(startDate.formatted(.dateTime.month().day())) - \(endDate.formatted(.dateTime.month().day()))"
            }
        case .sixMonths:
            if today >= startDate && today <= endDate {
                dateRange = "\(startDate.formatted(.dateTime.month().year())) - \(today.formatted(.dateTime.month().year()))"
            } else {
                dateRange = "\(startDate.formatted(.dateTime.month().year())) - \(endDate.formatted(.dateTime.month().year()))"
            }
        }
        
        return (average, steps, dateRange)
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
                .onChange(of: selectedStepRange) {
                    let calendar = Calendar.current
                    let today = calendar.startOfDay(for: Date())
                    switch selectedStepRange {
                    case .week:
                        scrollPosition = calendar.date(byAdding: .day, value: -6, to: today)!
                    case .month:
                        scrollPosition = calendar.date(byAdding: .day, value: -28, to: today)!
                    case .sixMonths:
                        scrollPosition = calendar.date(byAdding: .month, value: -5, to: calendar.date(from: calendar.dateComponents([.year, .month], from: today))!)!
                    }
                }
                HStack {
                    VStack(alignment: .leading) {
                        let data = stepsData()
                        Text(data.average)
                            .foregroundStyle(.secondary)
                            .font(.headline)
                        HStack(alignment: .bottom, spacing: 3) {
                            Text(data.steps)
                                .foregroundStyle(.primary)
                                .font(.largeTitle)
                            if data.steps != "No Data" {
                                Text("Steps")
                                    .foregroundStyle(.secondary)
                                    .offset(y: -4.0)
                            }
                        }
                        Text(data.dateRange)
                            .foregroundStyle(.secondary)
                            .font(.headline)
                    }
                    
                    Spacer()
                }
                .fontWeight(.medium)
                .padding(.bottom)
                Chart(graphableEntries(), id: \.date) { healthStep in
                    PointMark(x: .value("Date", healthStep.date), y: .value("Steps", healthStep.steps))
                        .foregroundStyle(Color.primary)
                    LineMark(
                        x: .value("Date", healthStep.date),
                        y: .value("Steps", healthStep.steps)
                    )
                    .foregroundStyle(Color.primary)
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
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
                                    .fill(Color(uiColor: UIColor.secondarySystemBackground))
                            }
                        }
                    }
                }
                .chartScrollableAxes(.horizontal)
                .chartXVisibleDomain(length: domainLength())
                .chartScrollTargetBehavior(.paging)
                .chartScrollPosition(x: $scrollPosition)
                .onChange(of: scrollPosition) {
                    scrollDatePosition = Calendar.current.startOfDay(for: scrollPosition)
                }
                .chartYScale(domain: yAxisRange())
                .chartXScale(domain: xAxisRange())
                .chartXSelection(value: $selectedDate)
                .onChange(of: selectedDate) { _, newValue in
                    if let newValue {
                        let calendar = Calendar.current
                        let entries = graphableEntries()

                        switch selectedStepRange {
                        case .week, .month:
                            let dayComponent = calendar.component(.day, from: newValue)
                            let monthComponent = calendar.component(.month, from: newValue)
                            if let currentEntry = entries.first(where: { item in
                                calendar.component(.day, from: item.date) == dayComponent &&
                                calendar.component(.month, from: item.date) == monthComponent
                            }) {
                                selectedEntry = currentEntry
                            } else {
                                selectedEntry = nil
                            }
                        case .sixMonths:
                            let weekOfYearComponent = calendar.component(.weekOfYear, from: newValue)
                            if let currentEntry = entries.first(where: { item in
                                calendar.component(.weekOfYear, from: item.date) == weekOfYearComponent
                            }) {
                                selectedEntry = currentEntry
                            } else {
                                selectedEntry = nil
                            }
                        }
                    } else {
                        selectedEntry = nil
                    }
                }
                .chartXAxis {
                    if selectedStepRange == .week {
                        AxisMarks(values: .automatic(desiredCount: 7)) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        }
                    } else if selectedStepRange == .month {
                        AxisMarks(values: .stride(by: .day, count: 7)) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(format: .dateTime.month().day())
                        }
                    } else {
                        AxisMarks(values: .stride(by: .month, count: 1)) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(format: .dateTime.month())
                        }
                    }
                }
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
