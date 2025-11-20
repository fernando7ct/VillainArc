import SwiftUI
import SwiftData

@main
struct VillainArcApp: App {
    @State private var dataContainer = DataContainer()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(dataContainer)
                .modelContainer(dataContainer.modelContainer)
        }
    }
}
