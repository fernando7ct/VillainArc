import SwiftUI

struct WeightTab: View {
    @State private var addWeightSheetActive = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    WeightGraphView()
                        .frame(height: 400)
                        .padding(.horizontal, -15)
                }
                .listRowBackground(Color.clear)
                
                Section {
                    NavigationLink(destination: AllWeightEntriesView()) {
                        HStack {
                            Text("All Weight Entries")
                                .foregroundStyle(Color.primary)
                        }
                        
                    }
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
