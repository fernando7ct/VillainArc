import SwiftUI
import MapKit
import SwiftData

struct GymSelectionView: View {
    @StateObject var locationManager = LocationManager.shared
    @State private var cameraPosition: MapCameraPosition = .automatic
    @FocusState var searchFocused: Bool
    @State private var selectedGym: MKMapItem?
    
    @Query private var users: [User]
    var user: User { return users.first! }
    
    private func isHomeGym(_ gym: MKMapItem) -> Bool {
        return user.homeGymLatitude == gym.placemark.coordinate.latitude && user.homeGymLongitude == gym.placemark.coordinate.longitude
    }
    
    var body: some View {
        ZStack {
            BackgroundView()
            VStack(spacing: 0) {
                if locationManager.locationEnabled {
                    Map(position: $cameraPosition, selection: $selectedGym) {
                        UserAnnotation()
                        ForEach(locationManager.filteredGyms, id: \.self) { gym in
                            Marker(item: gym)
                                .tint(isHomeGym(gym) ? .blue : .primary)
                        }
                    }
                    .mapControls {
                        MapUserLocationButton()
                    }
                    .frame(height: UIScreen.main.bounds.height / (searchFocused ? 5 : 3))
                    .mapStyle(.standard(elevation: .realistic))
                    .onChange(of: selectedGym) {
                        if let gym = selectedGym {
                            cameraPosition = .region(MKCoordinateRegion(center: gym.placemark.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)))
                        }
                    }
                }
                List {
                    Section {
                        TextField("Search", text: $locationManager.searchText, onCommit: {
                            locationManager.searchGyms()
                        })
                        .focused($searchFocused)
                        .listRowBackground(BlurView())
                    }
                    Section {
                        ForEach(locationManager.filteredGyms, id: \.self) { gym in
                            Button {
                                selectedGym = gym
                                cameraPosition = .region(MKCoordinateRegion(center: gym.placemark.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)))
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text(gym.placemark.name ?? "Unknown Gym")
                                            .foregroundStyle(isHomeGym(gym) ? .blue : .primary)
                                        Text(gym.placemark.title ?? "")
                                            .foregroundStyle(.secondary)
                                            .textScale(.secondary)
                                    }
                                    Spacer()
                                    Text("\(locationManager.calculateDistance(to: gym), specifier: "%.2f") mi")
                                        .font(.footnote)
                                        .foregroundStyle(isHomeGym(gym) ? .blue : .primary)
                                }
                                .fontWeight(.semibold)
                            }
                            .listRowBackground(BlurView())
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .sheet(item: $selectedGym) {
                GymDetailView(gym: $0)
                    .presentationDetents([.medium, .large])
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(locationManager.locationEnabled ? .hidden : .visible, for: .navigationBar)
            .animation(.smooth, value: searchFocused)
            .navigationTitle(locationManager.locationEnabled ? "" : "Set Home Gym")
        }
    }
}
extension MKMapItem: Identifiable {
    public var id: String {
        return "\(self.placemark.coordinate.latitude),\(self.placemark.coordinate.longitude)"
    }
}
struct GymDetailView: View {
    var gym: MKMapItem
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                BackgroundView()
                Form {
                    if let address = gym.placemark.title {
                        HStack {
                            Text(address)
                                .font(.body)
                            Spacer()
                            Button(action: {
                                openMaps(for: gym)
                            }) {
                                Image(systemName: "map.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .listRowBackground(BlurView())
                    }
                    if let phoneNumber = gym.phoneNumber {
                        HStack {
                            Text("Phone: \(phoneNumber)")
                                .font(.body)
                            Spacer()
                            Button(action: {
                                callPhoneNumber(phoneNumber)
                            }) {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .listRowBackground(BlurView())
                    }
                    if let url = gym.url {
                        HStack {
                            Text(trimmedURL(url))
                                .font(.body)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            Spacer()
                            Link(destination: url) {
                                Image(systemName: "link")
                                    .font(.body)
                                    .foregroundColor(.blue)
                            }
                        }
                        .listRowBackground(BlurView())
                    }
                    Section {
                        Button(action: {
                            DataManager.shared.saveHomeGym(gym: gym, context: modelContext)
                            dismiss()
                        }) {
                            Text("Set as Home Gym")
                                .fontWeight(.semibold)
                        }
                        .listRowBackground(Color.blue.opacity(0.5))
                    }
                }
                .navigationTitle(gym.placemark.name ?? "Unknown Gym")
                .navigationBarTitleDisplayMode(.large)
                .scrollContentBackground(.hidden)
            }
        }
    }

    private func openMaps(for gym: MKMapItem) {
        let mapItem = gym
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
    
    private func callPhoneNumber(_ phoneNumber: String) {
        let formattedPhoneNumber = phoneNumber.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
        if let phoneURL = URL(string: "tel://\(formattedPhoneNumber)"), UIApplication.shared.canOpenURL(phoneURL) {
            UIApplication.shared.open(phoneURL, options: [:], completionHandler: nil)
        }
    }
    
    private func trimmedURL(_ url: URL) -> String {
        let urlString = url.absoluteString
        let components = urlString.split(separator: "/")
        
        if components.count > 3 {
            return components.prefix(3).joined(separator: "/") + "/..."
        } else {
            return urlString
        }
    }
}

#Preview {
    GymSelectionView()
}
