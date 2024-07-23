import SwiftUI
import Charts
import SwiftData

enum GraphRanges {
    case week
    case month
    case sixMonths
}

struct GroupedWeight {
    var entries: [WeightEntry]
    var startDate: Date
    var previousEntries: [WeightEntry]
    
    init(entries: [WeightEntry], startDate: Date, previousEntries: [WeightEntry]) {
        self.entries = entries
        self.startDate = startDate
        self.previousEntries = previousEntries
    }
}

struct WeightView: View {
    @State private var addWeightSheetActive = false
    @Query(sort: \WeightEntry.date, order: .reverse) private var weightEntries: [WeightEntry]
    @State private var selectedWeightRange: GraphRanges = .week
    
    var groupedWeights: [GroupedWeight] {
        let calendar = Calendar.current
        var groupedObjects = [Date: [WeightEntry]]()
        
        for weight in weightEntries {
            switch selectedWeightRange {
            case .week:
                let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weight.date))!
                if groupedObjects[startOfWeek] == nil {
                    groupedObjects[startOfWeek] = [weight]
                } else {
                    groupedObjects[startOfWeek]?.append(weight)
                }
            case .month:
                let startOfMonth = calendar.date(from: calendar.dateComponents([.month, .year], from: weight.date))!
                if groupedObjects[startOfMonth] == nil {
                    groupedObjects[startOfMonth] = [weight]
                } else {
                    groupedObjects[startOfMonth]?.append(weight)
                }
            case .sixMonths:
                let components = calendar.dateComponents([.year, .month], from: weight.date)
                let month = components.month!
                let year = components.year!
                let startOfPeriod: Date
                if month <= 6 {
                    startOfPeriod = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
                } else {
                    startOfPeriod = calendar.date(from: DateComponents(year: year, month: 7, day: 1))!
                }
                if groupedObjects[startOfPeriod] == nil {
                    groupedObjects[startOfPeriod] = [weight]
                } else {
                    groupedObjects[startOfPeriod]?.append(weight)
                }
            }
        }
        let sortedObjects = groupedObjects.keys.sorted()
        let groupedWeights = sortedObjects.enumerated().map { index, key in
            let previousEntries = index > 0 ? groupedObjects[sortedObjects[index - 1]]! : []
            return GroupedWeight(entries: groupedObjects[key]!, startDate: key, previousEntries: previousEntries)
        }.sorted(by: { $0.startDate < $1.startDate })
        
        var newGrouped = groupedWeights
        
        for i in 0..<newGrouped.count {
            if i > 0 {
                newGrouped[i].entries.insert(groupedWeights[i - 1].entries.sorted(by: { $0.date < $1.date }).last!, at: 0)
            }
            if i < groupedWeights.count - 1 {
                newGrouped[i].entries.append(groupedWeights[i + 1].entries.sorted(by: { $0.date < $1.date }).first!)
            }
        }
        if newGrouped.isEmpty {
            let startDate: Date
            switch selectedWeightRange {
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
            newGrouped.append(GroupedWeight(entries: [], startDate: startDate, previousEntries: []))
        }
        return newGrouped.sorted(by: { $0.startDate < $1.startDate })
    }
    
    var body: some View {
        ZStack {
            BackgroundView()
            VStack {
                Picker("Time Range", selection: $selectedWeightRange) {
                    Text("Week").tag(GraphRanges.week)
                    Text("Month").tag(GraphRanges.month)
                    Text("6 Months").tag(GraphRanges.sixMonths)
                }
                .pickerStyle(.segmented)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(groupedWeights, id: \.startDate) { group in
                            WeightGraphView(weights: group.entries, previousWeights: group.previousEntries, startDate: group.startDate, selectedRange: selectedWeightRange)
                                .containerRelativeFrame(.horizontal)
                                .frame(height: 500)
                                .scrollTransition { content, phase in
                                    content
                                        .opacity(phase.isIdentity ? 1.0 : 0)
                                        .offset(y: phase.isIdentity ? 0 : 70)
                                }
                        }
                    }
                    .scrollTargetLayout()
                }
                .defaultScrollAnchor(.trailing)
                .scrollTargetBehavior(.viewAligned)
                .contentMargins(.horizontal, 8, for: .scrollContent)
                
                NavigationLink(value: 3) {
                    HStack {
                        Text("All Weight Entries")
                            .fontWeight(.semibold)
                    }
                    .hSpacing(.leading)
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
                .padding(.top)
                
                Spacer()
            }
            .padding(.horizontal)
            .navigationTitle("Weight")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationTitle("Weight")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    addWeightSheetActive = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color.primary)
                }
                .sheet(isPresented: $addWeightSheetActive) {
                    AddWeightEntryView()
                }
            }
        }
    }
}

struct WeightGraphView: View {
    var weights: [WeightEntry]
    var previousWeights: [WeightEntry]
    var startDate: Date
    var selectedRange: GraphRanges
    @State private var selectedDate: Date? = nil
    @State private var selectedEntry: WeightEntry? = nil
    
    private func yAxisRange() -> ClosedRange<Double> {
        guard let minWeight = weights.map({ $0.weight }).min(),
              let maxWeight = weights.map({ $0.weight }).max() else {
            return 0...100
        }
        return (minWeight < 5 ? 0 : minWeight - 5)...(maxWeight + 5)
    }
    
    private func averageWeight() -> Double {
        let dateRange = xAxisRange(startDate: startDate, selectedRange: selectedRange)
        let filteredWeights = weights.filter { dateRange.contains($0.date) }
        
        guard !filteredWeights.isEmpty else { return 0 }
        
        return filteredWeights.reduce(0) { $0 + $1.weight } / Double(filteredWeights.count)
    }
    private func previousAverageWeight() -> Double {
        guard !previousWeights.isEmpty else { return 0 }
        
        return previousWeights.reduce(0) { $0 + $1.weight } / Double(previousWeights.count)
    }
    private func percentageChange(current: Double, previous: Double) -> Double {
        guard previous != 0 else { return 0 }
        return ((current - previous) / previous) * 100
    }
    private func weightChange(current: Double, previous: Double) -> Double {
        return current - previous
    }
    private func trend() -> String {
        let current = averageWeight()
        let previous = previousAverageWeight()
        let change = percentageChange(current: current, previous: previous)
        
        return change > 0 ? "↑ \(String(format: "%.1f", change))%" : (change < 0 ? "↓ \(String(format: "%.1f", abs(change)))%" : "→ 0%")
    }
    private func weightChangeText() -> String {
        let current = averageWeight()
        let previous = previousAverageWeight()
        let change = percentageChange(current: current, previous: previous)
        return change > 0 ? "+\(formattedDouble(change)) lbs" : (change < 0 ? "\(formattedDouble(change)) lbs" : "Same Weight")
    }
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(weights.count > 1 ? "Average" : " ")
                        .foregroundStyle(.secondary)
                        .textScale(.secondary)
                    HStack(alignment: .bottom, spacing: 3) {
                        if averageWeight() != 0 {
                            Text("\(formattedDouble(averageWeight()))")
                                .font(.largeTitle)
                            Text("lbs")
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
                Spacer()
                if !previousWeights.isEmpty {
                    VStack(alignment: .trailing) {
                        Text("Trend")
                            .foregroundStyle(.secondary)
                            .textScale(.secondary)
                        Text(trend())
                            .font(.title)
                            .foregroundStyle(trend().contains("↓") ? .red : .green)
                        Text(weightChangeText())
                            .textScale(.secondary)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .fontWeight(.medium)
            Chart(weights.sorted(by: { $0.date < $1.date })) { weight in
                AreaMark(x: .value("Date", weight.date), yStart: .value("Weight", yAxisRange().lowerBound), yEnd: .value("Weight", weight.weight))
                    .foregroundStyle(Color.blue.opacity(0.4))
                    .interpolationMethod(.monotone)
                LineMark(x: .value("Date", weight.date), y: .value("Weight", weight.weight))
                    .foregroundStyle(Color.blue)
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                if let selectedEntry, xAxisRange(startDate: startDate, selectedRange: selectedRange).contains(selectedEntry.date) {
                    PointMark(x: .value("Date", selectedEntry.date), y: .value("Weight", selectedEntry.weight))
                        .foregroundStyle(Color.blue)
                    RuleMark(x: .value("Date", selectedEntry.date))
                        .foregroundStyle(Color.blue)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .annotation(position: .top, overflowResolution: .init(x: .fit(to: .plot), y: .fit(to: .chart))) {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("\(selectedEntry.date.formatted(.dateTime.month().day().year()))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack(alignment: .bottom, spacing: 3) {
                                    Text("\(formattedDouble(selectedEntry.weight))")
                                        .font(.title3)
                                    Text("lbs")
                                        .foregroundStyle(.secondary)
                                        .padding(.bottom, 1)
                                }
                            }
                            .fontWeight(.semibold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color(uiColor: UIColor.secondarySystemBackground))
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
                    let dayComponent = calendar.component(.day, from: selectedDate)
                    let monthComponent = calendar.component(.month, from: selectedDate)
                    let yearComponent = calendar.component(.year, from: selectedDate)
                    if let currentEntry = weights.first(where: { item in
                        calendar.component(.day, from: item.date) == dayComponent &&
                        calendar.component(.month, from: item.date) == monthComponent &&
                        calendar.component(.year, from: item.date) == yearComponent
                    }) {
                        selectedEntry = currentEntry
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
        WeightView()
    }
}
