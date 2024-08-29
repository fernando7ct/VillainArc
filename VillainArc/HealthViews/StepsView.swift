import SwiftUI
import Charts
import SwiftData

struct StepsView: View {
    @Query(sort: \HealthSteps.date, order: .reverse) private var healthSteps: [HealthSteps]
    @State private var selectedRange: GraphRanges = .month
    @State private var selectedDate: Date? = nil
    @State private var selectedWeekday: String? = nil
    @State private var updateGoal = false
    
    var filteredSteps: [HealthSteps] {
        let calendar = Calendar.current
        var startDate: Date {
            switch selectedRange {
            case .week:
                calendar.date(byAdding: .day, value: -7, to: .now.startOfDay)!
            case .month:
                calendar.date(byAdding: .month, value: -1, to: .now.startOfDay)!
            case .sixMonths:
                calendar.date(byAdding: .month, value: -6, to: .now.startOfDay)!
            case .year:
                calendar.date(byAdding: .year, value: -1, to: .now.startOfDay)!
            case .all:
                    .distantPast
            }
        }
        return healthSteps.filter({ $0.date >= startDate })
    }
    var averageSteps: Int {
        guard !healthSteps.isEmpty else { return 0 }
        return Int(filteredSteps.reduce(0) { $0 + $1.steps } / Double(filteredSteps.count))
    }
    var averageStepsPerWeekday: [(day: String, steps: Double)] {
        let calendar = Calendar.current
        let groupedSteps = Dictionary(grouping: healthSteps) { calendar.component(.weekday, from: $0.date) }
        
        return (1...7).compactMap { weekday -> (String, Double)? in
            if let steps = groupedSteps[weekday] {
                let average = Double(steps.reduce(0) { $0 + $1.steps }) / Double(steps.count)
                return (calendar.weekdaySymbols[weekday - 1], average)
            } else {
                return (calendar.weekdaySymbols[weekday - 1], 0)
            }
        }
    }
    var averageStepsPerWeek: Int {
        guard !averageStepsPerWeekday.isEmpty else { return 0 }
        return Int(averageStepsPerWeekday.reduce(0) { $0 + $1.steps })
    }
    private func yAxisRange() -> ClosedRange<Double> {
        guard let maxSteps = filteredSteps.map({ $0.steps }).max() else {
            return 0...10000
        }
        return 0...(maxSteps + 2000)
    }
    private func yAxisRange2() -> ClosedRange<Double> {
        guard let maxSteps = averageStepsPerWeekday.map({ $0.steps }).max() else {
            return 0...10000
        }
        return 0...(maxSteps + 3500)
    }
    private func xAxisRange() -> ClosedRange<Date> {
        let calendar = Calendar.current
        let endDate = Date.now.startOfDay
        let startDate: Date
        
        if healthSteps.isEmpty {
            startDate = endDate.startOfDay
        } else {
            let oldestEntryDate = healthSteps.map { $0.date }.min()!
            switch selectedRange {
            case .week:
                let weekStartDate = calendar.date(byAdding: .day, value: -7, to: endDate)!
                startDate = max(weekStartDate, oldestEntryDate)
            case .month:
                let monthStartDate = calendar.date(byAdding: .month, value: -1, to: endDate)!
                startDate = max(monthStartDate, oldestEntryDate)
            case .sixMonths:
                let sixMonthsStartDate = calendar.date(byAdding: .month, value: -6, to: endDate)!
                startDate = max(sixMonthsStartDate, oldestEntryDate)
            case .year:
                let yearStartDate = calendar.date(byAdding: .year, value: -1, to: endDate)!
                startDate = max(yearStartDate, oldestEntryDate)
            case .all:
                startDate = oldestEntryDate
            }
        }
        return startDate...endDate
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    if !healthSteps.isEmpty {
                        if let today = healthSteps.first(where: { $0.date == .now.startOfDay }) {
                            Text("Today")
                                .foregroundStyle(.secondary)
                                .textScale(.secondary)
                            Text("\(Int(today.steps)) Steps")
                                .font(.title)
                        } else if let mostRecent = healthSteps.first {
                            Text(mostRecent.date, format: .dateTime.month().day().year())
                                .foregroundStyle(.secondary)
                                .textScale(.secondary)
                            Text("\(Int(mostRecent.steps)) Steps")
                                .font(.title)
                        }
                        if filteredSteps.count > 1 {
                            Text("Avg: \(averageSteps) steps")
                                .foregroundStyle(.secondary)
                                .textScale(.secondary)
                                .fontWeight(.none)
                        }
                    } else {
                        Text("No Data")
                            .font(.title)
                    }
                }
                .hSpacing(.leading)
                .fontWeight(.semibold)
                .scrollTransition { content, phase in
                    content
                        .blur(radius: phase.isIdentity ? 0 : 1.5)
                        .opacity(phase.isIdentity ? 1 : 0.7)
                }
                
                Chart(filteredSteps) { day in
                    AreaMark(x: .value("Date", day.date), yStart: .value("Steps", 0), yEnd: .value("Steps", day.steps))
                        .foregroundStyle(Color.red.opacity(0.6))
                        .interpolationMethod(.monotone)
                    LineMark(x: .value("Date", day.date), y: .value("Steps", day.steps))
                        .foregroundStyle(Color.red)
                        .interpolationMethod(.monotone)
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                    if let selectedDate, selectedDate.isSameDayAs(day.date) {
                        PointMark(x: .value("Date", day.date), y: .value("Steps", day.steps))
                            .foregroundStyle(Color.red)
                        RuleMark(x: .value("Date", day.date))
                            .foregroundStyle(Color.red)
                            .lineStyle(StrokeStyle(lineWidth: 1.5))
                            .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("\(day.date.formatted(.dateTime.month().day().year()))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    HStack(alignment: .bottom, spacing: 3) {
                                        Text("\(Int(day.steps))")
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
                                .background(.red.gradient, in: .rect(cornerRadius: 6, style: .continuous))
                            }
                    }
                }
                .chartYScale(domain: yAxisRange())
                .chartXScale(domain: xAxisRange())
                .chartXAxis {}
                .chartXSelection(value: $selectedDate)
                .frame(height: 250)
                .scrollTransition { content, phase in
                    content
                        .blur(radius: phase.isIdentity ? 0 : 1.5)
                        .opacity(phase.isIdentity ? 1 : 0.7)
                }
                
                HStack {
                    Text(xAxisRange().lowerBound, format: .dateTime.month(.abbreviated).day().year())
                    Spacer()
                    Text("Today")
                        .padding(.trailing, 45)
                }
                .textScale(.secondary)
                .foregroundStyle(.secondary)
                .scrollTransition { content, phase in
                    content
                        .blur(radius: phase.isIdentity ? 0 : 1.5)
                        .opacity(phase.isIdentity ? 1 : 0.7)
                }
                
                Picker("Time Range", selection: $selectedRange) {
                    Text("W").tag(GraphRanges.week)
                    Text("M").tag(GraphRanges.month)
                    Text("6M").tag(GraphRanges.sixMonths)
                    Text("Y").tag(GraphRanges.year)
                    Text("All").tag(GraphRanges.all)
                }
                .pickerStyle(.segmented)
                .padding(.top)
                .scrollTransition { content, phase in
                    content
                        .blur(radius: phase.isIdentity ? 0 : 1.5)
                        .opacity(phase.isIdentity ? 1 : 0.7)
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: .rect(cornerRadius: 12, style: .continuous))
            .padding(.bottom)
            
            if healthSteps.count > 7 {
                VStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Average Steps Per Weekday")
                            .font(.title3)
                        Text("\(averageStepsPerWeek) steps/week")
                            .foregroundStyle(.secondary)
                            .textScale(.secondary)
                            .fontWeight(.none)
                    }
                    .fontWeight(.semibold)
                    .hSpacing(.leading)
                    .scrollTransition { content, phase in
                        content
                            .blur(radius: phase.isIdentity ? 0 : 1.5)
                            .opacity(phase.isIdentity ? 1 : 0.7)
                    }
                    
                    Chart(averageStepsPerWeekday, id: \.day) { day in
                        BarMark(x: .value("Weekday", day.day), y: .value("Steps", day.steps))
                            .foregroundStyle(.red.opacity(0.8))
                        if let selectedWeekday, selectedWeekday == day.day {
                            RuleMark(x: .value("Weekday", day.day))
                                .foregroundStyle(.red)
                                .lineStyle(StrokeStyle(lineWidth: 1.5))
                                .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text(day.day)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        HStack(alignment: .bottom, spacing: 3) {
                                            Text("\(Int(day.steps))")
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
                                    .background(.red.gradient, in: .rect(cornerRadius: 6, style: .continuous))
                                }
                        }
                    }
                    .chartXSelection(value: $selectedWeekday)
                    .chartYScale(domain: yAxisRange2())
                    .chartXAxis {
                        AxisMarks(values: .automatic) { value in
                            AxisValueLabel() {
                                if let day = value.as(String.self) {
                                    Text(day.prefix(3))
                                }
                            }
                        }
                    }
                    .frame(height: 250)
                    .scrollTransition { content, phase in
                        content
                            .blur(radius: phase.isIdentity ? 0 : 1.5)
                            .opacity(phase.isIdentity ? 1 : 0.7)
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: .rect(cornerRadius: 12, style: .continuous))
                
                Color.clear
                    .frame(height: 60)
            }
        }
        .padding(.horizontal)
        .vSpacing(.top)
        .safeAreaInset(edge: .top) {
            HStack {
                Text("Steps")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                Button {
                    updateGoal = true
                } label: {
                    Image(systemName: "figure.walk")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(8)
                        .background(.ultraThinMaterial, in: .circle)
                }
            }
            .padding()
            .sheet(isPresented: $updateGoal) {
                SetStepsGoalView()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
        .scrollIndicators(.hidden)
    }
}

#Preview {
    NavigationView {
        StepsView()
    }
}
