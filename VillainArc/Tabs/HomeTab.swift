import SwiftUI
import SwiftData

struct HomeTab: View {
    @Query(filter: #Predicate<Workout> { $0.template == false }) private var workouts: [Workout]
    @Query(sort: \WeightEntry.date, order: .reverse, animation: .smooth) private var weightEntries: [WeightEntry]
    @Query(sort: \HealthRestingEnergy.date, order: .reverse, animation: .smooth) private var restingEnergies: [HealthRestingEnergy]
    @Query(sort: \HealthWalkingRunningDistance.date, order: .reverse, animation: .smooth) private var walkingRunningDistances: [HealthWalkingRunningDistance]
    @Query(sort: \HealthSteps.date, order: .reverse, animation: .smooth) private var steps: [HealthSteps]
    @Query(sort: \HealthActiveEnergy.date, order: .reverse, animation: .smooth) private var activeEnergies: [HealthActiveEnergy]
    @Query private var users: [User]
    @Binding var selectedDate: Date
    @Binding var path: NavigationPath
    
    var startDate: Date {
        users.first!.dateJoined.startOfDay
    }
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                BackgroundView()
                ScrollView {
                    HeaderView(selectedDate: selectedDate)
                        .scrollTransition { content, phase in
                            content
                                .opacity(phase.isIdentity ? 1.0 : 0)
                        }
                    WeekDaysView(selectedDate: $selectedDate, startDate: startDate)
                        .scrollTransition { content, phase in
                            content
                                .opacity(phase.isIdentity ? 1.0 : 0)
                        }
                    if let workout = workouts.first(where: { $0.startTime.isSameDayAs(selectedDate) }) {
                        WorkoutCalendarView(workout: workout)
                            .scrollTransition { content, phase in
                                content
                                    .opacity(phase.isIdentity ? 1.0 : 0.1)
                            }
                    }
                    
                    if let weightEntry = weightEntries.first(where: { $0.date.isSameDayAs(selectedDate) }) {
                        WeightCalendarView(weightEntry: weightEntry)
                            .scrollTransition { content, phase in
                                content
                                    .opacity(phase.isIdentity ? 1.0 : 0.1)
                            }
                    }
                    
                    if let healthStep = steps.first(where: { $0.date.isSameDayAs(selectedDate) }), let walkingRunningDistance = walkingRunningDistances.first(where: { $0.date.isSameDayAs(selectedDate) }) {
                        StepsCalendarView(todaysSteps: healthStep.steps, todaysDistance: walkingRunningDistance.distance)
                            .scrollTransition { content, phase in
                                content
                                    .opacity(phase.isIdentity ? 1.0 : 0.1)
                            }
                    }
                    
                    if let activeEnergy = activeEnergies.first(where: { $0.date.isSameDayAs(selectedDate) }), let restingEnergy = restingEnergies.first(where: { $0.date.isSameDayAs(selectedDate) }) {
                        CaloriesCalendarView(activeCalories: activeEnergy.activeEnergy, restingCalories: restingEnergy.restingEnergy)
                            .scrollTransition { content, phase in
                                content
                                    .opacity(phase.isIdentity ? 1.0 : 0.1)
                            }
                    }
                }
                .navigationDestination(for: Workout.self) {
                    WorkoutDetailView(workout: $0)
                }
            }
        }
    }
}

struct WeekDaysView: View {
    @Binding var selectedDate: Date
    var startDate: Date
    
    var body: some View {
        let calendar = Calendar.current
        let today = Date()
        let weeks = generateWeeks(from: startDate, to: today)
        
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(weeks, id: \.self) { week in
                        HStack(spacing: 0) {
                            ForEach(week, id: \.self) { date in
                                VStack(spacing: 8) {
                                    Text(date, format: .dateTime.weekday())
                                        .fontWeight(.medium)
                                        .textScale(.secondary)
                                        .foregroundStyle(.secondary)
                                    Text(date, format: .dateTime.day())
                                        .fontWeight(.bold)
                                        .frame(width: 35, height: 35)
                                        .foregroundStyle(date > today || (date < startDate && calendar.isDate(date, equalTo: startDate, toGranularity: .weekOfYear)) ? .gray : .primary)
                                        .onTapGesture {
                                            if date <= today && !(date < startDate && calendar.isDate(date, equalTo: startDate, toGranularity: .weekOfYear)) {
                                                withAnimation(.snappy) {
                                                    selectedDate = date
                                                }
                                            }
                                        }
                                        .background {
                                            Circle()
                                                .fill(date == selectedDate ? .blue : Color.clear)
                                        }
                                        .id(date)
                                }
                                .hSpacing(.center)
                            }
                        }
                        .containerRelativeFrame(.horizontal)
                        .scrollTransition { content, phase in
                            content
                                .opacity(phase.isIdentity ? 1.0 : 0.1)
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .defaultScrollAnchor(.trailing)
            .scrollTargetBehavior(.viewAligned)
            .contentMargins(8, for: .scrollContent)
            .onChange(of: selectedDate) {
                if selectedDate == .now.startOfDay {
                    withAnimation {
                        proxy.scrollTo(selectedDate, anchor: .leading)
                    }
                }
            }
        }
    }
    
    private func generateWeeks(from startDate: Date, to endDate: Date) -> [[Date]] {
        let calendar = Calendar.current
        var weeks: [[Date]] = []
        var startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startDate))!
        
        while startOfWeek <= endDate {
            var week: [Date] = []
            for i in 0..<7 {
                if let day = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                    week.append(day)
                }
            }
            weeks.append(week)
            startOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
        }
        return weeks
    }
}

struct HeaderView: View {
    var selectedDate: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Text(selectedDate, format: .dateTime.month(.wide))
                    .foregroundStyle(.blue)
                Text(selectedDate, format: .dateTime.year())
                    .foregroundStyle(.secondary)
            }
            .fontWeight(.bold)
            .font(.largeTitle)
            
            Text(selectedDate, format: .dateTime.weekday(.wide).day().month(.wide).year())
                .foregroundStyle(.secondary)
                .fontWeight(.semibold)
                .textScale(.secondary)
            
        }
        .hSpacing(.leading)
        .padding(.leading)
    }
}
struct StepsCalendarView: View {
    var todaysSteps: Double
    var todaysDistance: Double
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .bottom, spacing: 2) {
                    Text(formattedDouble(todaysDistance))
                        .font(.title2)
                    Text("MILES")
                        .font(.subheadline)
                        .padding(.bottom, 2)
                }
                .foregroundStyle(Color.secondary)
                .padding(.top, 4)
                Text("\(Int(todaysSteps))")
                    .font(.largeTitle)
            }
            .fontWeight(.semibold)
            Spacer()
            VStack(alignment: .trailing) {
                Image(systemName: "figure.walk")
                    .font(.title2)
                    .padding(.bottom)
                Text("Steps")
                    .foregroundStyle(Color.secondary)
                    .font(.subheadline)
            }
            .fontWeight(.semibold)
        }
        .customStyle()
    }
}

struct CaloriesCalendarView: View {
    var activeCalories: Double
    var restingCalories: Double
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(Int(activeCalories))")
                        .font(.largeTitle)
                    Text("Active")
                        .foregroundStyle(Color.secondary)
                        .font(.title2)
                        .padding(.bottom, 3)
                }
                Spacer()
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(Int(activeCalories + restingCalories))")
                        .font(.largeTitle)
                    Text("Total")
                        .font(.title2)
                        .foregroundStyle(Color.secondary)
                        .padding(.bottom, 3)
                }
            }
            .fontWeight(.semibold)
            Spacer()
            VStack(alignment: .trailing) {
                Image(systemName: "flame.fill")
                    .font(.title2)
                Spacer()
                Text("Calories Burned")
                    .foregroundStyle(Color.secondary)
                    .font(.subheadline)
                    .padding(.bottom, 5)
            }
            .fontWeight(.semibold)
        }
        .customStyle()
    }
}
struct WeightCalendarView: View {
    var weightEntry: WeightEntry
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(weightEntry.date, format: .dateTime.month().day().year())
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                    .padding(.top, 4)
                HStack(alignment: .bottom, spacing: 4) {
                    Text(formattedDouble(weightEntry.weight))
                        .font(.largeTitle)
                    Text("lbs")
                        .font(.title2)
                        .foregroundStyle(Color.secondary)
                        .padding(.bottom, 3)
                }
            }
            .fontWeight(.semibold)
            Spacer()
            VStack(alignment: .trailing) {
                Image(systemName: "scalemass.fill")
                    .font(.title2)
                    .padding(.bottom)
                Text("Weight")
                    .foregroundStyle(Color.secondary)
                    .font(.subheadline)
                    .padding(.bottom, 5)
            }
            .fontWeight(.semibold)
        }
        .customStyle()
    }
}
struct WorkoutCalendarView: View {
    @State var workout: Workout
    
    var body: some View {
        NavigationLink(value: workout) {
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 0) {
                            Text(workout.title)
                            if !workout.template {
                                Text("\(workout.startTime.formatted(.dateTime.month().day().year()))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text(exerciseCategories(for: workout))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .fontWeight(.semibold)
                    }
                    Spacer()
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(workout.exercises.sorted(by: { $0.order < $1.order}).prefix(5)) { exercise in
                                HStack(spacing: 1) {
                                    Text("\(exercise.sets.count)x")
                                    Text(exercise.name)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                .lineLimit(1)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.vertical, 1)
                            }
                        }
                        if workout.exercises.count > 5 {
                            let remaining = workout.exercises.count - 5
                            HStack(spacing: 2) {
                                Image(systemName: "plus")
                                    .font(.subheadline)
                                Text("\(remaining)")
                                    .font(.headline)
                                Text("More")
                                    .font(.headline)
                            }
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.secondary)
                        }
                    }
                }
            }
            .customStyle()
        }
    }
}
