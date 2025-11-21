import SwiftUI
import SwiftData

@main
struct VillainArcApp: App {
    let dataContainer = DataContainer()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(dataContainer.modelContainer)
        }
    }
}
