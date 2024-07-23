import SwiftUI
import SwiftData

struct GymSectionView: View {
    @Query(filter: #Predicate<Gym> { $0.favorite }, animation: .smooth) private var gyms: [Gym]
    
    var homeGym: Gym? {
        return gyms.first
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Gym")
                    .fontWeight(.semibold)
                    .font(.title2)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 5)
            
            NavigationLink(value: 3) {
                HStack {
                    if let homeGym {
                        VStack(alignment: .leading) {
                            Text(homeGym.name)
                            Text(homeGym.address)
                                .textScale(.secondary)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                        }
                        .fontWeight(.semibold)
                        Spacer()
                            Button(action: {
                                LocationManager.shared.openMaps(latitude: homeGym.latitude, longitude: homeGym.longitude)
                            }) {
                                Image(systemName: "car.fill")
                                    .font(.title2)
                            }
                    } else {
                        Text("Set Home Gym")
                            .fontWeight(.medium)
                        Spacer()
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: .rect(cornerRadius: 12))
            }
            .padding(.horizontal)
        }
        .padding(.horizontal)
    }
}

#Preview {
    GymSectionView()
        .modelContainer(for: User.self)
}
