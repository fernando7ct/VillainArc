import SwiftUI

struct WeightTab: View {
    @State private var addWeightSheetActive = false
    
    var body: some View {
        NavigationView {
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
                    .customStyle()
                    .padding()
                }
            }
            .navigationTitle("Weight")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        addWeightSheetActive = true
                    }, label: {
                        Image(systemName: "plus")
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
