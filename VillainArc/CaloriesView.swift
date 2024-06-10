import SwiftUI
import Charts
import SwiftData

struct CaloriesView: View {
    @Query(sort: \HealthActiveEnergy.date, order: .reverse) private var healthActiveEnergy: [HealthActiveEnergy]
    @Query(sort: \HealthRestingEnergy.date, order: .reverse) private var healthRestingEnergy: [HealthRestingEnergy]
    @State private var selectedCaloriesRange: GraphRanges = .week
    @State private var selectedEntry: (date: Date, calories: Double)? = nil
    
    private func yAxisRange() -> ClosedRange<Double> {
        let filteredEntries = filteredEntries()
        guard let maxCalories = filteredEntries.map({ $0.calories }).max() else {
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
                return (start, end)
            case .month:
                let start = calendar.date(byAdding: .day, value: -28, to: today)!
                let end = calendar.date(byAdding: .day, value: 1, to: today)!
                return (start, end)
            case .sixMonths:
                let startOfPrevious5thMonth = calendar.date(byAdding: .month, value: -5, to: calendar.date(from: calendar.dateComponents([.year, .month], from: today))!)!
                let endOfCurrentMonth = calendar.date(byAdding: .month, value: 1, to: calendar.date(from: calendar.dateComponents([.year, .month], from: today))!)!
                return (startOfPrevious5thMonth, endOfCurrentMonth)
            }
        }()
        return startDate...endDate
    }
    
    private func filteredEntries() -> [(date: Date, calories: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let (startDate, endDate): (Date, Date) = {
            switch selectedCaloriesRange {
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
        
        let activeEnergy = healthActiveEnergy.filter { $0.date >= startDate && $0.date < endDate }
        let restingEnergy = healthRestingEnergy.filter { $0.date >= startDate && $0.date < endDate }
        
        var combinedEntries: [Date: Double] = [:]
        
        for entry in activeEnergy {
            combinedEntries[entry.date, default: 0] += entry.activeEnergy
        }
        
        for entry in restingEnergy {
            combinedEntries[entry.date, default: 0] += entry.restingEnergy
        }
        
        return combinedEntries.map { (date: $0.key, calories: $0.value) }.sorted { $0.date < $1.date }
    }
    
    private func graphableEntries() -> [(date: Date, calories: Double)] {
        let calendar = Calendar.current
        let entries = filteredEntries()
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
    
    private func caloriesData() -> (String, String, String) {
        let calendar = Calendar.current
        let entries = filteredEntries()
        let today = calendar.startOfDay(for: Date())
        
        var average: String
        var averageCalories: String
        var timeRange: String
        
        if entries.isEmpty {
            average = ""
            averageCalories = "No Data"
        } else if entries.count == 1 {
            average = ""
            averageCalories = "\(Int(entries.first!.calories))"
        } else {
            average = "Average"
            let average = entries.map { $0.calories }.reduce(0, +) / Double(entries.count)
            averageCalories = "\(Int(average))"
        }
        
        switch selectedCaloriesRange {
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
        
        return (average, averageCalories, timeRange)
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
                .padding(.top)
                HStack {
                    VStack(alignment: .leading) {
                        let (averageText, calories, range) = caloriesData()
                        Text(averageText)
                            .foregroundStyle(.secondary)
                            .font(.headline)
                        HStack(alignment: .bottom, spacing: 3) {
                            Text(calories)
                                .foregroundStyle(.primary)
                                .font(.largeTitle)
                            if calories != "No Data" {
                                Text("Calories")
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
                Chart(graphableEntries(), id: \.date) { entry in
                    if graphableEntries().count == 1 {
                        PointMark(x: .value("Date", entry.date), y: .value("Calories", entry.calories))
                            .foregroundStyle(Color.primary)
                    }
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Calories", entry.calories)
                    )
                    .foregroundStyle(Color.primary)
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                    AreaMark(
                        x: .value("Date", entry.date),
                        yStart: .value("Calories", yAxisRange().lowerBound),
                        yEnd: .value("Calories", entry.calories)
                    )
                    .foregroundStyle(Color.primary.gradient.opacity(0.6))
                    .interpolationMethod(.monotone)
                    if let selectedEntry {
                        RuleMark(
                            x: .value("Date", selectedEntry.date)
                        )
                        .foregroundStyle(Color.primary)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
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
                                    .fill(Color(uiColor: UIColor.secondarySystemBackground).shadow(.drop(radius: 2)))
                            }
                        }
                    }
                }
                .chartYScale(domain: yAxisRange())
                .chartXScale(domain: xAxisRange())
                .chartXAxis {
                    if selectedCaloriesRange == .week {
                        AxisMarks(values: .automatic(desiredCount: 7)) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        }
                    } else if selectedCaloriesRange == .month {
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
                                            
                                            switch selectedCaloriesRange {
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
            .navigationTitle("Calories")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    CaloriesView()
}
