import SwiftUI
import Charts
import SwiftData

struct CombinedCalories: Identifiable {
    var id = UUID()
    var activeEnergy: Double
    var restingEnergy: Double
    var date: Date
    var total: Double {
        return activeEnergy + restingEnergy
    }
    
    init(activeEnergy: Double, restingEnergy: Double, date: Date) {
        self.activeEnergy = activeEnergy
        self.restingEnergy = restingEnergy
        self.date = date
    }
}
struct GroupedCalories {
    var entries: [CombinedCalories]
    var startDate: Date
    var previousEntries: [CombinedCalories]
    
    init(entries: [CombinedCalories], startDate: Date, previousEntries: [CombinedCalories]) {
        self.entries = entries
        self.startDate = startDate
        self.previousEntries = previousEntries
    }
}

struct CaloriesView: View {
    @Query private var healthActiveEnergy: [HealthActiveEnergy]
    @Query private var healthRestingEnergy: [HealthRestingEnergy]
    @State private var selectedCaloriesRange: GraphRanges = .week
    
    var combinedEntries: [CombinedCalories] {
        var combinedEntries: [CombinedCalories] = []
        let calendar = Calendar.current
        
        for entry in healthActiveEnergy {
            if let matchingRestingEntry = healthRestingEnergy.first(where: { calendar.isDate($0.date, inSameDayAs: entry.date) }) {
                combinedEntries.append(CombinedCalories(activeEnergy: entry.activeEnergy, restingEnergy: matchingRestingEntry.restingEnergy, date: entry.date))
            } else {
                combinedEntries.append(CombinedCalories(activeEnergy: entry.activeEnergy, restingEnergy: 0, date: entry.date))
            }
        }
        for entry in healthRestingEnergy {
            if !combinedEntries.contains(where: { calendar.isDate($0.date, inSameDayAs: entry.date) }) {
                combinedEntries.append(CombinedCalories(activeEnergy: 0, restingEnergy: entry.restingEnergy, date: entry.date))
            }
        }
        return combinedEntries.sorted { $0.date < $1.date }
    }
    var groupedCalories: [GroupedCalories] {
        let calendar = Calendar.current
        var groupedObjects = [Date: [CombinedCalories]]()
        
        for entry in combinedEntries {
            switch selectedCaloriesRange {
            case .week:
                let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: entry.date))!
                if groupedObjects[startOfWeek] == nil {
                    groupedObjects[startOfWeek] = [entry]
                } else {
                    groupedObjects[startOfWeek]?.append(entry)
                }
            case .month:
                let startOfMonth = calendar.date(from: calendar.dateComponents([.month, .year], from: entry.date))!
                if groupedObjects[startOfMonth] == nil {
                    groupedObjects[startOfMonth] = [entry]
                } else {
                    groupedObjects[startOfMonth]?.append(entry)
                }
            case .sixMonths:
                let components = calendar.dateComponents([.year, .month], from: entry.date)
                let month = components.month!
                let year = components.year!
                let startOfPeriod: Date
                if month <= 6 {
                    startOfPeriod = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
                } else {
                    startOfPeriod = calendar.date(from: DateComponents(year: year, month: 7, day: 1))!
                }
                if groupedObjects[startOfPeriod] == nil {
                    groupedObjects[startOfPeriod] = [entry]
                } else {
                    groupedObjects[startOfPeriod]?.append(entry)
                }
            }
        }
        
        let sortedObjects = groupedObjects.keys.sorted()
        var groupedCalories = sortedObjects.enumerated().map { index, key in
            let previousEntries = index > 0 ? groupedObjects[sortedObjects[index - 1]]! : []
            return GroupedCalories(entries: groupedObjects[key]!, startDate: key, previousEntries: previousEntries)
        }.sorted(by: { $0.startDate < $1.startDate })
        
        if groupedCalories.isEmpty {
            let startDate: Date
            switch selectedCaloriesRange {
            case .week:
                startDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
            case .month:
                startDate = calendar.date(from: calendar.dateComponents([.month, .year], from: Date()))!
            case .sixMonths:
                let components = calendar.dateComponents([.year, .month], from: Date())
                let month = components.month!
                let year = components.year!
                if month <= 6 {
                    startDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
                } else {
                    startDate = calendar.date(from: DateComponents(year: year, month: 7, day: 1))!
                }
            }
            groupedCalories.append(GroupedCalories(entries: [], startDate: startDate, previousEntries: []))
        }
        return groupedCalories.sorted(by: { $0.startDate < $1.startDate })
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
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(groupedCalories, id: \.startDate) { group in
                            CaloriesGraphView(calories: group.entries, previousCalories: group.previousEntries, startDate: group.startDate, selectedRange: selectedCaloriesRange)
                                .containerRelativeFrame(.horizontal)
                                .frame(height: 500)
                                .scrollTransition { content, phase in
                                    content
                                        .opacity(phase.isIdentity ? 1.0 : 0.1)
                                        .offset(y: phase.isIdentity ? 0 : 70)
                                }
                        }
                    }
                    .scrollTargetLayout()
                }
                .defaultScrollAnchor(.trailing)
                .scrollTargetBehavior(.viewAligned)
                .contentMargins(.horizontal, 8, for: .scrollContent)
                
                Spacer()
            }
            .padding(.horizontal)
            .navigationTitle("Calories Burned")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct CaloriesGraphView: View {
    var calories: [CombinedCalories]
    var previousCalories: [CombinedCalories]
    var startDate: Date
    var selectedRange: GraphRanges
    @State private var showTotal = false
    @State private var selectedDate: Date? = nil
    @State private var selectedEntry: CombinedCalories? = nil
    
    private func yAxisRange() -> ClosedRange<Double> {
        guard let maxCalories = graphCalories.map({ $0.total }).max() else {
            return 0...2000
        }
        if showTotal && selectedRange == .sixMonths {
            return 0...(maxCalories + 5000)
        }
        return 0...(maxCalories + 300)
    }
    private func averageCalories() -> Double {
        guard !calories.isEmpty else { return 0 }
        return calories.reduce(0) { $0 + $1.total } / Double(calories.count)
    }
    private func previousAverageCalories() -> Double {
        guard !previousCalories.isEmpty else { return 0 }
        return previousCalories.reduce(0) { $0 + $1.total } / Double(previousCalories.count)
    }
    private func totalCalories() -> Double {
        guard !calories.isEmpty else { return 0 }
        return calories.reduce(0) { $0 + $1.total }
    }
    private func previousTotalCalories() -> Double {
        guard !previousCalories.isEmpty else { return 0 }
        return previousCalories.reduce(0) { $0 + $1.total }
    }
    private func percentageChange() -> Double {
        let current = showTotal ? totalCalories() : averageCalories()
        let previous = showTotal ? previousTotalCalories() : previousAverageCalories()
        guard previous != 0 else { return 0 }
        return ((current - previous) / previous) * 100
    }
    private func caloriesChange() -> Double {
        let current = showTotal ? totalCalories() : averageCalories()
        let previous = showTotal ? previousTotalCalories() : previousAverageCalories()
        return current - previous
    }
    private func trend() -> String {
        let change = percentageChange()
        return change > 0 ? "↑ \(String(format: "%.1f", change))%" : (change < 0 ? "↓ \(String(format: "%.1f", abs(change)))%" : "0%")
    }
    
    var graphCalories: [CombinedCalories] {
        if selectedRange == .sixMonths {
            return calories.groupedByMonth().map { month in
                var active: Double
                var resting: Double
                if showTotal {
                    active = month.entries.reduce(0) { $0 + $1.activeEnergy }
                    resting = month.entries.reduce(0) { $0 + $1.restingEnergy }
                } else {
                    active = month.entries.reduce(0) { $0 + $1.activeEnergy } / Double(month.entries.count)
                    resting = month.entries.reduce(0) { $0 + $1.restingEnergy } / Double(month.entries.count)
                }
                
                return CombinedCalories(activeEnergy: active, restingEnergy: resting, date: month.startDate)
            }
        } else {
            return calories
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    if showTotal {
                        Text("Total")
                            .foregroundStyle(.secondary)
                            .textScale(.secondary)
                    } else {
                        Text(calories.count > 1 ? "Daily Average" : " ")
                            .foregroundStyle(.secondary)
                            .textScale(.secondary)
                    }
                    HStack(alignment: .bottom, spacing: 3) {
                        if !calories.isEmpty {
                            Text("\(Int(showTotal ? totalCalories() : averageCalories()))")
                                .font(.largeTitle)
                            Text("Calories")
                                .foregroundStyle(.secondary)
                                .offset(y: -4.0)
                        } else {
                            Text("No Data")
                                .font(.largeTitle)
                        }
                    }
                    Text(dateRange(startDate: startDate, selectedRange: selectedRange))
                        .foregroundStyle(.secondary)
                        .textScale(.secondary)
                }
                .onTapGesture {
                    withAnimation(.easeIn) {
                        showTotal.toggle()
                    }
                }
                Spacer()
                if !previousCalories.isEmpty {
                    VStack(alignment: .trailing) {
                        Text("Trend")
                            .foregroundStyle(.secondary)
                            .textScale(.secondary)
                        Text(trend())
                            .font(.title)
                            .foregroundStyle(trend().contains("↓") ? .red : .green)
                        let change = caloriesChange()
                        Text(change > 0 ? "+\(Int(change)) cals\(!showTotal ? "/day" : "")" : (change < 0 ? "\(Int(change)) cals\(!showTotal ? "/day" : "")" : "Same Cals"))
                            .textScale(.secondary)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .fontWeight(.medium)
            Chart(graphCalories) { day in
                BarMark(x: .value("Date", adjustDate(day.date, selectedRange: selectedRange)), yStart: .value("Calories", 0), yEnd: .value("Calories", day.total), width: selectedRange == .month ? 8 : 30)
                    .foregroundStyle(Color.red.gradient)
                BarMark(x: .value("Date", adjustDate(day.date, selectedRange: selectedRange)), yStart: .value("Calories", 0), yEnd: .value("Calories", day.activeEnergy), width: selectedRange == .month ? 8 : 30)
                    .foregroundStyle(Color.orange.gradient)
                if let selectedEntry {
                    RuleMark(x: .value("Date", adjustDate(selectedEntry.date, selectedRange: selectedRange)))
                        .foregroundStyle(Color.red)
                        .lineStyle(StrokeStyle(lineWidth: 0.1))
                        .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                            VStack(alignment: .leading, spacing: 0) {
                                Text(annotationDate(for: selectedEntry.date, selectedRange: selectedRange))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack(alignment: .bottom, spacing: 3) {
                                    Text("\(Int(selectedEntry.activeEnergy))")
                                        .font(.title3)
                                        .foregroundStyle(.white)
                                    Text("Active")
                                        .foregroundStyle(.secondary)
                                        .padding(.bottom, 1)
                                }
                                HStack(alignment: .bottom, spacing: 3) {
                                    Text("\(Int(selectedEntry.total))")
                                        .font(.title3)
                                        .foregroundStyle(.white)
                                    Text("Total")
                                        .foregroundStyle(.secondary)
                                        .padding(.bottom, 1)
                                }
                            }
                            .fontWeight(.semibold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Gradient(colors: [.orange, .red, .red]))
                            }
                        }
                }
            }
            .animation(.easeIn, value: selectedRange)
            .chartYScale(domain: yAxisRange())
            .chartXScale(domain: xAxisRange(startDate: startDate, selectedRange: selectedRange))
            .chartXAxis {
                switch selectedRange {
                case .week:
                    AxisMarks(values: .automatic(desiredCount: 7)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true)
                    }
                case .month:
                    AxisMarks(values: .stride(by: .day, count: 8)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                case .sixMonths:
                    AxisMarks(values: .stride(by: .month, count: 1)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month(), centered: true)
                    }
                }
            }
            .chartXSelection(value: $selectedDate)
            .onChange(of: selectedDate) {
                if let selectedDate {
                    let calendar = Calendar.current
                    let entries = graphCalories
                    
                    let dayComponent = calendar.component(.day, from: selectedDate)
                    let monthComponent = calendar.component(.month, from: selectedDate)
                    let yearComponent = calendar.component(.year, from: selectedDate)
                    if selectedRange == .sixMonths {
                        if let currentEntry = entries.first(where: { item in
                            calendar.component(.month, from: item.date) == monthComponent &&
                            calendar.component(.year, from: item.date) == yearComponent
                        }) {
                            selectedEntry = currentEntry
                        }
                    } else {
                        if let currentEntry = entries.first(where: { item in
                            calendar.component(.day, from: item.date) == dayComponent &&
                            calendar.component(.month, from: item.date) == monthComponent &&
                            calendar.component(.year, from: item.date) == yearComponent
                        }) {
                            selectedEntry = currentEntry
                        }
                    }
                } else {
                    selectedEntry = nil
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        CaloriesView()
    }
}

extension Array where Element == CombinedCalories {
    func groupedByMonth() -> [GroupedCalories] {
        let calendar = Calendar.current
        var groupedObjects = [Date: [CombinedCalories]]()
        
        for entry in self {
            let startOfMonth = calendar.date(from: calendar.dateComponents([.month, .year], from: entry.date))!
            if groupedObjects[startOfMonth] == nil {
                groupedObjects[startOfMonth] = [entry]
            } else {
                groupedObjects[startOfMonth]?.append(entry)
            }
        }
        return groupedObjects.keys.sorted().map { key in
            GroupedCalories(entries: groupedObjects[key]!, startDate: key, previousEntries: [])
        }
    }
}
