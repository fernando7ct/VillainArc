import SwiftUI
import SwiftData

struct GymSectionView: View {
    @Query(animation: .smooth) private var users: [User]
    
    var user: User {
        return users.first!
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
                    if let homeGymName = user.homeGymName, let homeGymAddress = user.homeGymAddress {
                        VStack(alignment: .leading) {
                            Text(homeGymName)
                            Text(homeGymAddress)
                                .textScale(.secondary)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                        }
                        .fontWeight(.semibold)
                        Spacer()
                        if let latitude = user.homeGymLatitude, let longitude = user.homeGymLongitude {
                            Button(action: {
                                LocationManager.shared.openMaps(latitude: latitude, longitude: longitude)
                            }) {
                                Image(systemName: "car.fill")
                                    .font(.title2)
                            }
                        }
                    } else {
                        Text("Set Home Gym")
                            .fontWeight(.medium)
                        Spacer()
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
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
