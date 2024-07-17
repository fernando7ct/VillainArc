import SwiftUI

struct WeightView: View {
    @State private var addWeightSheetActive = false
    
    var body: some View {
        ZStack {
            BackgroundView()
            ScrollView {
                WeightGraphView()
                    .frame(height: 500)
                    .padding(.horizontal)
                
                NavigationLink(value: 3) {
                    HStack {
                        Text("All Weight Entries")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .customStyle()
                }
                .padding(.top)
            }
            .scrollDisabled(true)
        }
        .navigationTitle("Weight")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    addWeightSheetActive = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color.primary)
                }
                .sheet(isPresented: $addWeightSheetActive) {
                    AddWeightEntryView()
                }
            }
        }
    }
}

#Preview {
    WeightView()
}
