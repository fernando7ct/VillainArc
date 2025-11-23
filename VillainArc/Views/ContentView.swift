import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        TabView {
            Tab(Tabs.workout.rawValue, systemImage: Tabs.workout.iconString) {
                WorkoutTab()
            }
        }
        .onAppear {
            DataManager.seedExercisesIfNeeded(context: context)
        }
    }
}

#Preview {
    ContentView()
        .sampleDataConainer()
}
