import SwiftUI
import Charts
import SwiftData

struct CaloriesView: View {
    @Query(sort: \HealthEnergy.date, order: .reverse) private var healthEnergy: [HealthEnergy]
    @State private var selectedRange: GraphRanges = .month
    @State private var selectedDate: Date? = nil
    @State private var selectedWeekday: String? = nil
    
    var filteredCalories: [HealthEnergy] {
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
        return healthEnergy.filter({ $0.date >= startDate })
    }
    var averageCalories: Int {
        guard !healthEnergy.isEmpty else { return 0 }
        return Int(filteredCalories.reduce(0) { $0 + $1.total } / Double(filteredCalories.count))
    }
    var averageCaloriesPerWeekday: [(day: String, calories: Double)] {
        let calendar = Calendar.current
        let groupedCalories = Dictionary(grouping: healthEnergy) { calendar.component(.weekday, from: $0.date) }
        
        return (1...7).compactMap { weekday -> (String, Double)? in
            if let calories = groupedCalories[weekday] {
                let average = Double(calories.reduce(0) { $0 + $1.total }) / Double(calories.count)
                return (calendar.weekdaySymbols[weekday - 1], average)
            } else {
                return (calendar.weekdaySymbols[weekday - 1], 0)
            }
        }
    }
    var averageCaloriesPerWeek: Int {
        guard !averageCaloriesPerWeekday.isEmpty else { return 0 }
        return Int(averageCaloriesPerWeekday.reduce(0) { $0 + $1.calories })
    }
    private func yAxisRange() -> ClosedRange<Double> {
        guard let maxCalories = filteredCalories.map({ $0.total }).max() else {
            return 0...2000
        }
        return 0...(maxCalories + 500)
    }
    private func yAxisRange2() -> ClosedRange<Double> {
        guard let maxCalories = averageCaloriesPerWeekday.map({ $0.calories }).max() else {
            return 0...2000
        }
        return 0...(maxCalories + 750)
    }
    private func xAxisRange() -> ClosedRange<Date> {
        let calendar = Calendar.current
        let endDate = Date.now.startOfDay
        let startDate: Date
        
        if healthEnergy.isEmpty {
            startDate = endDate
        } else {
            let oldestEntryDate = healthEnergy.map { $0.date }.min()!
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
                    if !healthEnergy.isEmpty {
                        if let today = healthEnergy.first(where: { $0.date == .now.startOfDay }) {
                            Text("Today")
                                .foregroundStyle(.secondary)
                                .textScale(.secondary)
                            Text("\(Int(today.total)) Calories")
                                .font(.title)
                        } else if let mostRecent = healthEnergy.first {
                            Text(mostRecent.date, format: .dateTime.month().day().year())
                                .foregroundStyle(.secondary)
                                .textScale(.secondary)
                            Text("\(Int(mostRecent.total)) Calories")
                                .font(.title)
                        }
                        if filteredCalories.count > 1 {
                            Text("Avg: \(averageCalories) calories")
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
                
                Chart(filteredCalories) { day in
                    AreaMark(x: .value("Date", day.date), yStart: .value("Calories", 0), yEnd: .value("Calories", day.total))
                        .foregroundStyle(Color.orange.opacity(0.6))
                        .interpolationMethod(.monotone)
                    LineMark(x: .value("Date", day.date), y: .value("Calories", day.total))
                        .foregroundStyle(Color.orange)
                        .interpolationMethod(.monotone)
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                    if let selectedDate, selectedDate.isSameDayAs(day.date) {
                        PointMark(x: .value("Date", day.date), y: .value("Calories", day.total))
                            .foregroundStyle(Color.orange)
                        RuleMark(x: .value("Date", day.date))
                            .foregroundStyle(Color.orange)
                            .lineStyle(StrokeStyle(lineWidth: 1.5))
                            .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("\(day.date.formatted(.dateTime.month().day().year()))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    HStack(alignment: .bottom, spacing: 3) {
                                        Text("\(Int(day.activeEnergy))")
                                            .font(.title3)
                                            .foregroundStyle(.white)
                                        Text("Active")
                                            .foregroundStyle(.secondary)
                                            .padding(.bottom, 1)
                                    }
                                    HStack(alignment: .bottom, spacing: 3) {
                                        Text("\(Int(day.total))")
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
                                .background(.orange.gradient, in: .rect(cornerRadius: 6, style: .continuous))
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
                        .padding(.trailing, 40)
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
            
            if healthEnergy.count > 7 {
                VStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Average Calories Per Weekday")
                            .font(.title3)
                        Text("\(averageCaloriesPerWeek) calories/week")
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
                    
                    Chart(averageCaloriesPerWeekday, id: \.day) { day in
                        BarMark(x: .value("Weekday", day.day), y: .value("Steps", day.calories))
                            .foregroundStyle(.orange.opacity(0.8))
                        if let selectedWeekday, selectedWeekday == day.day {
                            RuleMark(x: .value("Weekday", day.day))
                                .foregroundStyle(.orange)
                                .lineStyle(StrokeStyle(lineWidth: 1.5))
                                .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text(day.day)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        HStack(alignment: .bottom, spacing: 3) {
                                            Text("\(Int(day.calories))")
                                                .font(.title3)
                                                .foregroundStyle(.white)
                                            Text("Calories")
                                                .foregroundStyle(.secondary)
                                                .padding(.bottom, 1)
                                        }
                                    }
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(.orange.gradient, in: .rect(cornerRadius: 6, style: .continuous))
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
                Text("Calories Burned")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding()
        }
        .scrollIndicators(.hidden)
    }
}

#Preview {
    NavigationView {
        CaloriesView()
    }
}
