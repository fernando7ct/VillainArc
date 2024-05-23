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
                    .foregroundStyle(Color.primary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color(uiColor: UIColor.secondarySystemBackground).shadow(.drop(radius: 2)))
                    }
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
