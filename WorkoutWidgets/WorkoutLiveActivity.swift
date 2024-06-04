import WidgetKit
import SwiftUI
import ActivityKit

struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutAttributes.self) { context in
            WorkoutLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom")
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T")
            } minimal: {
                Text("M")
            }
        }
    }
}

struct WorkoutLiveActivityView: View {
    let context: ActivityViewContext<WorkoutAttributes>
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    Text(context.attributes.workoutTitle)
                        .font(.headline)
                    Text("Total time: \(context.attributes.totalTime.formattedTime())")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }
                Spacer()
                if context.state.timeRemaining > 0 {
                    VStack {
                        Text("Rest Time")
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                        Text(context.state.timeRemaining.formattedTime())
                            .font(.headline)
                    }
                }
            }
            .padding(.bottom)
            if context.state.allExercisesDone {
                Text("All exercises done")
                    .font(.title2)
                    .foregroundStyle(.green)
            } else {
                VStack(alignment: .leading) {
                    Text(context.state.currentExerciseName)
                        .font(.headline)
                    if !context.state.notes.isEmpty {
                        Text("Notes: \(context.state.notes)")
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                    }
                    Text(context.state.currentSetDetails)
                        .font(.body)
                        .foregroundStyle(Color.secondary)
                }
            }
        }
        .padding()
    }
}

extension TimeInterval {
    func formattedTime() -> String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
