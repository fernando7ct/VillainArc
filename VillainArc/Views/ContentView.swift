import SwiftUI

struct ContentView: View {
    
    var body: some View {
        TabView {
            Tab(Tabs.workout.rawValue, systemImage: Tabs.workout.iconString) {
                WorkoutTab()
            }
        }
    }
}

#Preview {
    ContentView()
        .sampleDataConainer()
}
