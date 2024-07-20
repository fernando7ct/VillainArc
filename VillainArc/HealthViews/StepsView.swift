import SwiftUI
import Charts
import SwiftData

struct GroupedSteps {
    var entries: [HealthSteps]
    var startDate: Date
    
    init(entries: [HealthSteps], startDate: Date) {
        self.entries = entries
        self.startDate = startDate
    }
    
}

struct StepsView: View {
    @Query private var healthSteps: [HealthSteps]
    @State private var selectedStepRange: GraphRanges = .week
    @State private var showTotal = false
    
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
        var groupedSteps = sortedObjects.map { key in
            GroupedSteps(entries: groupedObjects[key]!, startDate: key)
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
            groupedSteps.append(GroupedSteps(entries: [], startDate: startDate))
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
                            StepsGraphView(steps: group.entries, startDate: group.startDate, selectedRange: selectedStepRange, showTotal: $showTotal)
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
func xAxisRange(startDate: Date, selectedRange: GraphRanges) -> ClosedRange<Date> {
    let calendar = Calendar.current
    let endDate: Date
    switch selectedRange {
    case .week:
        endDate = calendar.date(byAdding: .day, value: 7, to: startDate)!
    case .month:
        endDate = calendar.date(byAdding: .month, value: 1, to: startDate)!
    case .sixMonths:
        endDate = calendar.date(byAdding: .month, value: 6, to: startDate)!
    }
    return startDate...endDate
}
func adjustDate(_ date: Date, selectedRange: GraphRanges) -> Date {
    let calendar = Calendar.current
    if selectedRange == .sixMonths {
        return calendar.date(byAdding: .day, value: 15, to: date)!
    } else {
        return calendar.date(byAdding: .hour, value: 12, to: date)!
    }
}
func dateRange(startDate: Date, selectedRange: GraphRanges) -> String {
    let calendar = Calendar.current
    switch selectedRange {
    case .week:
        let endDate = calendar.date(byAdding: .day, value: 6, to: startDate)!
        return "\(startDate.formatted(.dateTime.month().day())) - \(endDate.formatted(.dateTime.month().day()))"
    case .month:
        return "\(startDate.formatted(.dateTime.month(.wide).year()))"
    case .sixMonths:
        let endDate = calendar.date(byAdding: .month, value: 5, to: startDate)!
        return "\(startDate.formatted(.dateTime.month(.wide).year())) - \(endDate.formatted(.dateTime.month(.wide).year()))"
    }
}
func annotationDate(for date: Date, selectedRange: GraphRanges) -> String {
    if selectedRange == .sixMonths {
        return "\(date.formatted(.dateTime.month().year()))"
    } else {
        return "\(date.formatted(.dateTime.month().day().year()))"
    }
}
struct StepsGraphView: View {
    var steps: [HealthSteps]
    var startDate: Date
    var selectedRange: GraphRanges
    @Binding var showTotal: Bool
    @State private var selectedDate: Date? = nil
    @State private var selectedEntry: HealthSteps? = nil
    
    private func yAxisRange() -> ClosedRange<Double> {
        guard let maxSteps = graphSteps.map({ $0.steps }).max() else {
            return 0...1000
        }
        if showTotal && selectedRange == .sixMonths {
            return 0...(maxSteps + 10000)
        }
        return 0...(maxSteps + 3000)
    }
    private func averageSteps() -> Double {
        guard !steps.isEmpty else { return 0 }
        return steps.reduce(0) { $0 + $1.steps } / Double(steps.count)
    }
    private func totalSteps() -> Double {
        guard !steps.isEmpty else { return 0 }
        return steps.reduce(0) { $0 + $1.steps }
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
            GroupedSteps(entries: groupedObjects[key]!, startDate: key)
        }
    }
}
