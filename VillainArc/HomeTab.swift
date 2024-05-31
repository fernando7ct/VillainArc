import SwiftUI

struct HomeTab: View {
    @State private var workoutStarted: Bool = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                Button(action: {
                    workoutStarted.toggle()
                }, label: {
                    Text("Workout")
                })
                .fullScreenCover(isPresented: $workoutStarted) {
                    WorkoutView()
                }
            }
            .navigationTitle("Home")
        }
    }
}

#Preview {
    HomeTab()
}
