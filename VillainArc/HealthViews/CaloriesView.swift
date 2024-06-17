import SwiftUI
import Charts
import SwiftData

struct CaloriesView: View {
    @Query(sort: \HealthActiveEnergy.date, order: .reverse) private var healthActiveEnergy: [HealthActiveEnergy]
    @Query(sort: \HealthRestingEnergy.date, order: .reverse) private var healthRestingEnergy: [HealthRestingEnergy]
    @State private var selectedCaloriesRange: GraphRanges = .week
    @State private var selectedEntry: (date: Date, calories: Double)? = nil
    @State private var selectedDate: Date?
    @State private var scrollPosition = Calendar.current.date(byAdding: .day, value: -6, to: Calendar.current.startOfDay(for: Date()))!
    @State private var scrollDatePosition: Date = Date()
    
    private func combinedEntries() -> [(date: Date, calories: Double)] {
        let activeEnergy = healthActiveEnergy
        let restingEnergy = healthRestingEnergy
        
        var combinedEntries: [Date: Double] = [:]
        for entry in activeEnergy {
            combinedEntries[entry.date, default: 0] += entry.activeEnergy
        }
        for entry in restingEnergy {
            combinedEntries[entry.date, default: 0] += entry.restingEnergy
        }
        return combinedEntries.map { (date: $0.key, calories: $0.value) }.sorted { $0.date < $1.date }
    }
    private func domainLength() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        switch selectedCaloriesRange {
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
        guard let maxCalories = combinedEntries().map({ $0.calories }).max() else {
            return 0...1000
        }
        return 0...(maxCalories + 100)
    }
    
    private func xAxisRange() -> ClosedRange<Date> {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let (startDate, endDate): (Date, Date) = {
            switch selectedCaloriesRange {
            case .week:
                let start = calendar.date(byAdding: .day, value: -6, to: today)!
                let end = calendar.date(byAdding: .day, value: 1, to: today)!
                let rangeDifference = end.timeIntervalSince(start)
                if let firstEntry = healthActiveEnergy.last {
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
                if let firstEntry = healthActiveEnergy.last {
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
                if let firstEntry = healthActiveEnergy.last {
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
    private func graphableEntries() -> [(date: Date, calories: Double)] {
        let calendar = Calendar.current
        let entries = combinedEntries()
        var averages: [(date: Date, calories: Double)] = []
        
        if selectedCaloriesRange == .sixMonths {
            let groupedByWeek = Dictionary(grouping: entries, by: { calendar.dateInterval(of: .weekOfYear, for: $0.date)!.start })
            for (startOfWeek, entries) in groupedByWeek {
                let totalCalories = entries.reduce(0) { $0 + $1.calories }
                let average = totalCalories / Double(entries.count)
                averages.append((date: startOfWeek, calories: average))
            }
        } else {
            averages = entries
        }
        
        return averages.sorted { $0.date < $1.date }
    }
    private func caloriesData() -> (average: String, calories: String, dateRange: String) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let (startDate, endDate): (Date, Date) = {
            switch selectedCaloriesRange {
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
        
        let entries = combinedEntries().filter { $0.date >= startDate && $0.date <= endDate}
        var average: String
        var calories: String
        if entries.isEmpty {
            average = " "
            calories = "No Data"
        } else if entries.count == 1 {
            average = " "
            calories = "\(Int(entries.first!.calories))"
        } else {
            average = "Average"
            let averageCalories = entries.map { $0.calories }.reduce(0, +) / Double(entries.count)
            calories = "\(Int(averageCalories))"
        }
        
        var dateRange: String
        switch selectedCaloriesRange {
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
        
        return (average, calories, dateRange)
    }
    private func annotationPosition() -> AnnotationPosition {
        guard let selectedEntry else { return .top }
        let calendar = Calendar.current
        let start: Date
        let end: Date
        switch selectedCaloriesRange {
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
        ZStack {
            BackgroundView()
            VStack {
                Picker("Time Range", selection: $selectedCaloriesRange) {
                    Text("Week").tag(GraphRanges.week)
                    Text("Month").tag(GraphRanges.month)
                    Text("6 Months").tag(GraphRanges.sixMonths)
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedCaloriesRange) {
                    let calendar = Calendar.current
                    let today = calendar.startOfDay(for: Date())
                    switch selectedCaloriesRange {
                    case .week:
                        scrollPosition = calendar.date(byAdding: .day, value: -6, to: today)!
                    case .month:
                        scrollPosition = calendar.date(byAdding: .day, value: -28, to: today)!
                    case .sixMonths:
                        scrollPosition = calendar.date(byAdding: .month, value: -5, to: calendar.date(from: calendar.dateComponents([.year, .month], from: today))!)!
                    }
                }
                .padding(.top)
                HStack {
                    VStack(alignment: .leading) {
                        let data = caloriesData()
                        Text(data.average)
                            .foregroundStyle(.secondary)
                            .font(.headline)
                        HStack(alignment: .bottom, spacing: 3) {
                            Text(data.calories)
                                .foregroundStyle(.primary)
                                .font(.largeTitle)
                            if data.calories != "No Data" {
                                Text("Calories")
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
                Chart(graphableEntries(), id: \.date) { entry in
                    PointMark(x: .value("Date", entry.date), y: .value("Calories", entry.calories))
                        .foregroundStyle(Color.primary)
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Calories", entry.calories)
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
                        .annotation(position: annotationPosition(), overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Calories")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(Int(selectedEntry.calories))")
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

                        switch selectedCaloriesRange {
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
                    if selectedCaloriesRange == .week {
                        AxisMarks(values: .automatic(desiredCount: 7)) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        }
                    } else if selectedCaloriesRange == .month {
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
            .navigationTitle("Calories Burned")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    CaloriesView()
}
