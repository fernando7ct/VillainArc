import SwiftUI

struct WeightTab: View {
    @State private var addWeightSheetActive = false
    
    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView()
                ScrollView {
                    WeightGraphView()
                        .frame(height: 400)
                        .padding()
                    
                    NavigationLink(destination: AllWeightEntriesView()) {
                        HStack {
                            Text("All Weight Entries")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundStyle(Color.primary)
                        .padding()
                        .background(BlurView())
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .scrollDisabled(true)
            }
            .navigationTitle("Weight")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        addWeightSheetActive = true
                    }, label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.primary)
                    })
                    .sheet(isPresented: $addWeightSheetActive) {
                        AddWeightEntryView()
                    }
                }
            }

        }
    }
}

#Preview {
    WeightTab()
}
