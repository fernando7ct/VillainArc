import WidgetKit
import SwiftUI
import SwiftData

struct Provider: TimelineProvider {
    @MainActor func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), entry: getNutritionEntry())
    }

    @MainActor func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), entry: getNutritionEntry())
        completion(entry)
    }

    @MainActor func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let timeline = Timeline(entries: [SimpleEntry(date: .now, entry: getNutritionEntry())], policy: .after(.now.advanced(by: 60 * 5)))
        completion(timeline)
    }
    
    @MainActor
    private func getNutritionEntry() -> NutritionEntry? {
        guard let modelContainer = try? ModelContainer(for: NutritionEntry.self) else {
            return nil
        }
        let descriptor = FetchDescriptor<NutritionEntry>(sortBy: [SortDescriptor(\NutritionEntry.date, order: .reverse)])
        let entries = try? modelContainer.mainContext.fetch(descriptor)
        
        return entries?.first
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let entry: NutritionEntry?
}

struct WorkoutLiveActivityEntryView: View {
    var entry: Provider.Entry
    
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            Text("Villain Arc")
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
    }
}

struct MediumWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let entry = entry.entry {
                Text("\(entry.date.formatted(.dateTime.month(.wide).day().weekday(.wide)))")
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                HStack(spacing: 5) {
                    WidgetTile(macroName: "Calories", consumed: entry.caloriesConsumed, goal: entry.caloriesGoal, cals: true)
                    WidgetTile(macroName: "Protein", consumed: entry.proteinConsumed, goal: entry.proteinGoal, cals: false)
                }
                HStack(spacing: 5) {
                    WidgetTile(macroName: "Carbs", consumed: entry.carbsConsumed, goal: entry.carbsGoal, cals: false)
                    WidgetTile(macroName: "Fat", consumed: entry.fatConsumed, goal: entry.fatGoal, cals: false)
                }
            } else {
                Text("Villain Arc")
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct WidgetTile: View {
    @State var macroName: String
    @State var consumed: Double
    @State var goal: Double
    @State var cals: Bool
    
    var body: some View {
        VStack {
            Text(macroName)
                .foregroundStyle(.secondary)
                .textScale(.secondary)
            Text("\(Int(consumed)) / \(Int(goal)) \(cals ? "" : "g")")
                .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 8))
    }
}

struct WorkoutLiveActivity: Widget {
    let kind: String = "WorkoutLiveActivity"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WorkoutLiveActivityEntryView(entry: entry)
                .containerBackground(.ultraThinMaterial, for: .widget)
        }
        .configurationDisplayName("Villain Arc")
        .description("View your macros for today.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    WorkoutLiveActivity()
} timeline: {
    SimpleEntry(date: .now, entry: nil)
    SimpleEntry(date: .now, entry: nil)
}
