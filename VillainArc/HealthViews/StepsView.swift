import SwiftUI
import Charts
import SwiftData

struct GroupedSteps {
    var entries: [HealthSteps]
    var startDate: Date
    var previousEntries: [HealthSteps]
    
    init(entries: [HealthSteps], startDate: Date, previousEntries: [HealthSteps]) {
        self.entries = entries
        self.startDate = startDate
        self.previousEntries = previousEntries
    }
    
}

struct StepsView: View {
    @Query(filter: #Predicate<HealthSteps> { $0.steps != 0 }) private var healthSteps: [HealthSteps]
    @State private var selectedStepRange: GraphRanges = .week
    
    var groupedSteps: [GroupedSteps] {
        let calendar = Calendar.current
        var groupedObjects = [Date: [HealthSteps]]()
        
        for step in healthSteps {
            switch selectedStepRange {
            case .week:
                let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: step.date))!
                if groupedObjects[startOfWeek] == nil {
                    groupedObjects[startOfWeek] = [step]
                } else {
                    groupedObjects[startOfWeek]?.append(step)
                }
            case .month:
                let startOfMonth = calendar.date(from: calendar.dateComponents([.month, .year], from: step.date))!
                if groupedObjects[startOfMonth] == nil {
                    groupedObjects[startOfMonth] = [step]
                } else {
                    groupedObjects[startOfMonth]?.append(step)
                }
            case .sixMonths:
                let components = calendar.dateComponents([.year, .month], from: step.date)
                let month = components.month!
                let year = components.year!
                let startOfPeriod: Date
                if month <= 6 {
                    startOfPeriod = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
                } else {
                    startOfPeriod = calendar.date(from: DateComponents(year: year, month: 7, day: 1))!
                }
                if groupedObjects[startOfPeriod] == nil {
                    groupedObjects[startOfPeriod] = [step]
                } else {
                    groupedObjects[startOfPeriod]?.append(step)
                }
            }
        }
        
        let sortedObjects = groupedObjects.keys.sorted()
        var groupedSteps = sortedObjects.enumerated().map { index, key in
            let previousEntries = index > 0 ? groupedObjects[sortedObjects[index - 1]]! : []
            return GroupedSteps(entries: groupedObjects[key]!, startDate: key, previousEntries: previousEntries)
        }.sorted(by: { $0.startDate < $1.startDate })
        
        if groupedSteps.isEmpty {
            let startDate: Date
            switch selectedStepRange {
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
            groupedSteps.append(GroupedSteps(entries: [], startDate: startDate, previousEntries: []))
        }
        return groupedSteps.sorted(by: { $0.startDate < $1.startDate })
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
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(groupedSteps, id: \.startDate) { group in
                            StepsGraphView(steps: group.entries, previousSteps: group.previousEntries, startDate: group.startDate, selectedRange: selectedStepRange)
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
            .navigationTitle("Steps")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct StepsGraphView: View {
    var steps: [HealthSteps]
    var previousSteps: [HealthSteps]
    var startDate: Date
    var selectedRange: GraphRanges
    @State private var showTotal = false
    @State private var selectedDate: Date? = nil
    @State private var selectedEntry: HealthSteps? = nil
    
    private func yAxisRange() -> ClosedRange<Double> {
        guard let maxSteps = graphSteps.map({ $0.steps }).max() else {
            return 0...1000
        }
        if showTotal && selectedRange == .sixMonths {
            return 0...(maxSteps + 10000)
        }
        return 0...(maxSteps + 2000)
    }
    private func averageSteps() -> Double {
        guard !steps.isEmpty else { return 0 }
        return steps.reduce(0) { $0 + $1.steps } / Double(steps.count)
    }
    private func previousAverageSteps() -> Double {
        guard !previousSteps.isEmpty else { return 0 }
        return previousSteps.reduce(0) { $0 + $1.steps } / Double(previousSteps.count)
    }
    private func totalSteps() -> Double {
        guard !steps.isEmpty else { return 0 }
        return steps.reduce(0) { $0 + $1.steps }
    }
    private func previousTotalSteps() -> Double {
        guard !previousSteps.isEmpty else { return 0 }
        return previousSteps.reduce(0) { $0 + $1.steps }
    }
    private func percentageChange() -> Double {
        let current = showTotal ? totalSteps() : averageSteps()
        let previous = showTotal ? previousTotalSteps() : previousAverageSteps()
        guard previous != 0 else { return 0 }
        return ((current - previous) / previous) * 100
    }
    private func stepsChange() -> Double {
        let current = showTotal ? totalSteps() : averageSteps()
        let previous = showTotal ? previousTotalSteps() : previousAverageSteps()
        return current - previous
    }
    private func trend() -> String {
        let change = percentageChange()
        return change > 0 ? "↑ \(String(format: "%.1f", change))%" : (change < 0 ? "↓ \(String(format: "%.1f", abs(change)))%" : "0%")
    }

    var graphSteps: [HealthSteps] {
        if selectedRange == .sixMonths {
            return steps.groupedByMonth().map { month in
                var steps: Double
                if showTotal {
                    steps = month.entries.reduce(0) { $0 + $1.steps }
                } else {
                    steps = month.entries.reduce(0) { $0 + $1.steps } / Double(month.entries.count)
                }
                return HealthSteps(id: UUID().uuidString, date: month.startDate, steps: steps)
            }
        } else {
            return steps
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
                        Text(steps.count > 1 ? "Daily Average" : " ")
                            .foregroundStyle(.secondary)
                            .textScale(.secondary)
                    }
                    HStack(alignment: .bottom, spacing: 3) {
                        if !steps.isEmpty {
                            Text("\(Int(showTotal ? totalSteps() : averageSteps()))")
                                .font(.largeTitle)
                            Text("Steps")
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
                if !previousSteps.isEmpty {
                    VStack(alignment: .trailing) {
                        Text("Trend")
                            .foregroundStyle(.secondary)
                            .textScale(.secondary)
                        Text(trend())
                            .font(.title)
                            .foregroundStyle(trend().contains("↓") ? .red : .green)
                        let change = stepsChange()
                        Text(change > 0 ? "+\(Int(change)) steps\(!showTotal ? "/day" : "")" : (change < 0 ? "\(Int(change)) steps\(!showTotal ? "/day" : "")" : "Same Steps"))
                            .textScale(.secondary)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .fontWeight(.medium)
            Chart(graphSteps) { day in
                BarMark(x: .value("Date", adjustDate(day.date, selectedRange: selectedRange)), y: .value("Steps", day.steps), width: selectedRange == .month ? 8 : 30)
                    .foregroundStyle(Color.red.gradient)
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
                                    Text("\(Int(selectedEntry.steps))")
                                        .font(.title3)
                                        .foregroundStyle(.white)
                                    Text("Steps")
                                        .foregroundStyle(.secondary)
                                        .padding(.bottom, 1)
                                }
                            }
                            .fontWeight(.semibold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color.red.gradient)
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
                    let entries = graphSteps
                    
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
        StepsView()
    }
}

extension Array where Element == HealthSteps {
    func groupedByMonth() -> [GroupedSteps] {
        let calendar = Calendar.current
        var groupedObjects = [Date: [HealthSteps]]()
        
        for entry in self {
            let startOfMonth = calendar.date(from: calendar.dateComponents([.month, .year], from: entry.date))!
            if groupedObjects[startOfMonth] == nil {
                groupedObjects[startOfMonth] = [entry]
            } else {
                groupedObjects[startOfMonth]?.append(entry)
            }
        }
        return groupedObjects.keys.sorted().map { key in
            GroupedSteps(entries: groupedObjects[key]!, startDate: key, previousEntries: [])
        }
    }
}
