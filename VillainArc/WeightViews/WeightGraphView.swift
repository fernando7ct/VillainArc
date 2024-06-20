import SwiftUI
import SwiftData
import Charts

enum GraphRanges {
    case week
    case month
    case sixMonths
}

struct WeightGraphView: View {
    @Query(sort: \WeightEntry.date, order: .reverse) private var weightEntries: [WeightEntry]
    @State private var selectedWeightRange: GraphRanges = .week
    @State private var selectedDate: Date?
    @State private var selectedEntry: (date: Date, weight: Double)? = nil
    @State private var scrollPosition = Calendar.current.date(byAdding: .day, value: -6, to: Calendar.current.startOfDay(for: Date()))!
    @State private var scrollDatePosition: Date = Date()
    
    private func domainLength() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        switch selectedWeightRange {
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
        guard let minWeight = weightEntries.map({ $0.weight }).min(),
              let maxWeight = weightEntries.map({ $0.weight }).max() else {
            return 0...100
        }
        return (minWeight < 5 ? 0 : minWeight - 5)...(maxWeight + 5)
    }
    
    private func xAxisRange() -> ClosedRange<Date> {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let (startDate, endDate): (Date, Date) = {
            switch selectedWeightRange {
            case .week:
                let start = calendar.date(byAdding: .day, value: -6, to: today)!
                let end = calendar.date(byAdding: .day, value: 1, to: today)!
                let rangeDifference = end.timeIntervalSince(start)
                if let firstEntry = weightEntries.last {
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
                if let firstEntry = weightEntries.last {
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
                if let firstEntry = weightEntries.last {
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
    private func graphableEntries() -> [(date: Date, weight: Double)] {
        let calendar = Calendar.current
        let entries = weightEntries
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
    private func weightData() -> (average: String, weight: String, dateRange: String) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let (startDate, endDate): (Date, Date) = {
            switch selectedWeightRange {
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
        
        let entries = weightEntries.filter { $0.date >= startDate && $0.date <= endDate}
        var average: String
        var weight: String
        if entries.isEmpty {
            average = " "
            weight = "No Data"
        } else if entries.count == 1 {
            average = " "
            weight = formattedDouble(entries.first!.weight)
        } else {
            average = "Average"
            let averageWeight = entries.map { $0.weight }.reduce(0, +) / Double(entries.count)
            weight = formattedDouble(averageWeight)
        }
        
        var dateRange: String
        switch selectedWeightRange {
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
        
        return (average, weight, dateRange)
    }
    private func annotationPosition() -> AnnotationPosition {
        guard let selectedEntry else { return .top }
        let calendar = Calendar.current
        let start: Date
        let end: Date
        switch selectedWeightRange {
        case .week:
            start = calendar.date(byAdding: .day, value: 1, to: scrollPosition)!
            end = calendar.date(byAdding: .day, value: 5, to: start)!
        case .month:
            start = calendar.date(byAdding: .day, value: 3, to: scrollPosition)!
            end = calendar.date(byAdding: .day, value: 29, to: start)!
        case .sixMonths:
            return .top
        }
        if selectedEntry.date < start {
            return .topTrailing
        } else if selectedEntry.date > end {
            return .topLeading
        } else {
            return .top
        }
    }
    
    var body: some View {
        VStack {
            Picker("Time Range", selection: $selectedWeightRange) {
                Text("Week").tag(GraphRanges.week)
                Text("Month").tag(GraphRanges.month)
                Text("6 Months").tag(GraphRanges.sixMonths)
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedWeightRange) {
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                switch selectedWeightRange {
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
                    let data = weightData()
                    Text(data.average)
                        .foregroundStyle(.secondary)
                        .font(.headline)
                    HStack(alignment: .bottom, spacing: 3) {
                        Text(data.weight)
                            .foregroundStyle(.primary)
                            .font(.largeTitle)
                        if data.weight != "No Data" {
                            Text("lbs")
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
            Chart(graphableEntries(), id: \.date) { weightEntry in
                PointMark(x: .value("Date", weightEntry.date), y: .value("Weight", weightEntry.weight))
                    .foregroundStyle(Color.primary)
                LineMark(
                    x: .value("Date", weightEntry.date),
                    y: .value("Weight", weightEntry.weight)
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
                    .annotation(position: annotationPosition(), overflowResolution: .init(x: .fit(to: .plot), y: .fit(to: .chart))) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Weight")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(formattedDouble(selectedEntry.weight)) lbs")
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

                    switch selectedWeightRange {
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
                if selectedWeightRange == .week {
                    AxisMarks(values: .automatic(desiredCount: 7)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    }
                } else if selectedWeightRange == .month {
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
        }
    }
}

#Preview {
    WeightGraphView()
}
