import SwiftUI
import MapKit
import SwiftData

struct GymSelectionView: View {
    @StateObject var locationManager = LocationManager.shared
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedGym: MKMapItem?
    @State private var viewingRegion: MKCoordinateRegion?
    @Query(filter: #Predicate<Gym> { $0.favorite }) private var gyms: [Gym]
    var homeGym: Gym? { return gyms.first }
    @Namespace private var locationSpace
    
    @State private var sheetDetent: PresentationDetent = .height(UIScreen.main.bounds.height / 3)
    @State private var previousDetent: PresentationDetent?
    @State private var showSheet = true
    
    private func isHomeGym(_ gym: MKMapItem) -> Bool {
        if let homeGym {
            return homeGym.latitude == gym.placemark.coordinate.latitude && homeGym.longitude == gym.placemark.coordinate.longitude
        } else {
            return false
        }
    }
    var gymListView: some View {
        ZStack {
            BackgroundView()
            ScrollView {
                Section {
                    TextField("Search", text: $locationManager.searchText, onCommit: {
                        locationManager.searchGyms(in: viewingRegion)
                        cameraPosition = .automatic
                    })
                    .customStyle()
                    .padding(.top)
                }
                Section {
                    ForEach(locationManager.filteredGyms, id: \.self) { gym in
                        Button {
                            selectedGym = gym
                            let adjustedCoordinate = CLLocationCoordinate2D(latitude: gym.placemark.coordinate.latitude - 0.01, longitude: gym.placemark.coordinate.longitude)
                            cameraPosition = .region(MKCoordinateRegion(center: adjustedCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)))
                            if sheetDetent == .large {
                                sheetDetent = .height(UIScreen.main.bounds.height / 3)
                                previousDetent = .large
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(gym.placemark.name ?? "Unknown Gym")
                                        .foregroundStyle(isHomeGym(gym) ? .blue : .primary)
                                    Text(gym.placemark.title ?? "")
                                        .foregroundStyle(.secondary)
                                        .textScale(.secondary)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()
                                let distance = locationManager.calculateDistance(to: gym)
                                Text(distance == 0 ? "" : "\(formattedDouble(distance)) mi")
                                    .font(.footnote)
                                    .foregroundStyle(isHomeGym(gym) ? .blue : .primary)
                            }
                            .fontWeight(.semibold)
                        }
                        .customStyle()
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .sheet(item: $selectedGym, onDismiss: { 
                if let _ = previousDetent {
                    sheetDetent = .large
                    previousDetent = nil
                }
            }) {
                GymDetailView(gym: $0)
                    .presentationDetents([.height(UIScreen.main.bounds.height / 3), .large])
            }
        }
    }
    var body: some View {
        Group {
            if locationManager.locationEnabled {
                Map(position: $cameraPosition, selection: $selectedGym, scope: locationSpace) {
                    UserAnnotation()
                    ForEach(locationManager.filteredGyms, id: \.self) { gym in
                        Marker(item: gym)
                            .tint(isHomeGym(gym) ? .blue : .primary)
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapPitchToggle()
                }
                .mapScope(locationSpace)
                .onMapCameraChange({ ctx in
                    viewingRegion = ctx.region
                })
                .mapStyle(.standard(elevation: .realistic))
                .sheet(isPresented: $showSheet) {
                    gymListView
                        .interactiveDismissDisabled()
                        .presentationDetents([.height(60), .height(UIScreen.main.bounds.height / 3), .large], selection: $sheetDetent)
                        .presentationBackgroundInteraction(.enabled)
                        .presentationCornerRadius(20)
                }
                .toolbarBackground(.hidden, for: .navigationBar)
            } else {
                gymListView
                    .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                    .navigationTitle("Set Home Gym")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
extension MKMapItem: Identifiable {
    public var id: String {
        return "\(self.placemark.coordinate.latitude),\(self.placemark.coordinate.longitude)"
    }
}
#Preview {
    GymSelectionView()
}
