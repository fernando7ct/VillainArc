import SwiftUI
import SwiftData
import UIKit

struct CalendarView: UIViewRepresentable {
    let interval: DateInterval
    var workouts: [Workout]
    var weightEntries: [WeightEntry]
    @Binding var dateSelected: DateComponents?
    @Binding var displaySheet: Bool

    func makeUIView(context: Context) -> UICalendarView {
        let view = UICalendarView()
        view.delegate = context.coordinator
        view.calendar = Calendar(identifier: .gregorian)
        view.availableDateRange = interval
        let dateSelection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        view.selectionBehavior = dateSelection
        return view
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self, workouts: workouts, weightEntries: weightEntries)
    }

    func updateUIView(_ uiView: UICalendarView, context: Context) {
        // Update the calendar view if necessary
    }

    class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        var parent: CalendarView
        var workouts: [Workout]
        var weightEntries: [WeightEntry]

        init(parent: CalendarView, workouts: [Workout], weightEntries: [WeightEntry]) {
            self.parent = parent
            self.workouts = workouts
            self.weightEntries = weightEntries
        }

        @MainActor
        func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            let hasWorkouts = workouts.contains { Calendar.current.isDate($0.startTime, inSameDayAs: dateComponents.date ?? Date()) }
            let hasWeightEntries = weightEntries.contains { Calendar.current.isDate($0.date, inSameDayAs: dateComponents.date ?? Date()) }

            if hasWorkouts || hasWeightEntries {
                if hasWorkouts && hasWeightEntries {
                    return .customView {
                        let view = TwoDotsView()
                        view.translatesAutoresizingMaskIntoConstraints = false
                        return view
                    }
                } else {
                    return .customView {
                        let view = DotView()
                        view.translatesAutoresizingMaskIntoConstraints = false
                        return view
                    }
                }
            }
            return nil
        }

        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            parent.dateSelected = dateComponents
            guard let dateComponents else { return }
            let foundWorkouts = workouts.filter {
                Calendar.current.isDate($0.startTime, inSameDayAs: dateComponents.date ?? Date())
            }
            let foundWeightEntries = weightEntries.filter {
                Calendar.current.isDate($0.date, inSameDayAs: dateComponents.date ?? Date())
            }
            if !foundWorkouts.isEmpty || !foundWeightEntries.isEmpty {
                parent.displaySheet.toggle()
            }
        }

        func dateSelection(_ selection: UICalendarSelectionSingleDate, canSelectDate dateComponents: DateComponents?) -> Bool {
            return true
        }
    }
}

struct CalendarTestingView: View {
    @Query(filter: #Predicate<Workout> { workout in
        !workout.template
    }, sort: \Workout.startTime, order: .reverse) var workouts: [Workout]
    @Query(sort: \WeightEntry.date, order: .reverse) var weightEntries: [WeightEntry]
    @State private var dateSelected: DateComponents?
    @State private var displaySheet = false

    var body: some View {
        NavigationView {
            CalendarView(interval: DateInterval(start: .distantPast, end: .distantFuture), workouts: workouts, weightEntries: weightEntries, dateSelected: $dateSelected, displaySheet: $displaySheet)
                .frame(height: 200)
        }
    }
}

class DotView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        let dot = UIView()
        dot.backgroundColor = .systemBlue
        dot.layer.cornerRadius = 5
        dot.translatesAutoresizingMaskIntoConstraints = false

        addSubview(dot)

        NSLayoutConstraint.activate([
            dot.centerXAnchor.constraint(equalTo: centerXAnchor),
            dot.centerYAnchor.constraint(equalTo: centerYAnchor),
            dot.widthAnchor.constraint(equalToConstant: 10),
            dot.heightAnchor.constraint(equalToConstant: 10)
        ])
    }
}

class TwoDotsView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        let dot1 = UIView()
        dot1.backgroundColor = .systemBlue
        dot1.layer.cornerRadius = 5
        dot1.translatesAutoresizingMaskIntoConstraints = false

        let dot2 = UIView()
        dot2.backgroundColor = .systemRed
        dot2.layer.cornerRadius = 5
        dot2.translatesAutoresizingMaskIntoConstraints = false

        addSubview(dot1)
        addSubview(dot2)

        NSLayoutConstraint.activate([
            dot1.centerYAnchor.constraint(equalTo: centerYAnchor),
            dot1.leadingAnchor.constraint(equalTo: leadingAnchor),
            dot1.widthAnchor.constraint(equalToConstant: 10),
            dot1.heightAnchor.constraint(equalToConstant: 10),

            dot2.centerYAnchor.constraint(equalTo: centerYAnchor),
            dot2.trailingAnchor.constraint(equalTo: trailingAnchor),
            dot2.widthAnchor.constraint(equalToConstant: 10),
            dot2.heightAnchor.constraint(equalToConstant: 10)
        ])
    }
}
