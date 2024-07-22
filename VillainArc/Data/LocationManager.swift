import SwiftUI
import CoreLocation
import MapKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    @Published var locationEnabled = false
    @Published var retrievedGyms: [MKMapItem] = []
    @Published var filteredGyms: [MKMapItem] = []
    @Published var searchText: String = "" { didSet { filterGyms() } }
    
    private var locationManager = CLLocationManager()
    
    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            locationEnabled = false
        case .authorizedAlways, .authorizedWhenInUse, .authorized:
            locationEnabled = true
            searchGyms()
        @unknown default:
            locationEnabled = false
        }
    }
    
    func searchGyms() {
        let request = MKLocalSearch.Request()
        let emptySearch = searchText.isEmpty
        request.naturalLanguageQuery = emptySearch ? "Gym" : searchText
        request.resultTypes = .pointOfInterest
        if locationEnabled, let userLocation = locationManager.location {
            request.region = MKCoordinateRegion(center: userLocation.coordinate, span: MKCoordinateSpan(latitudeDelta: emptySearch ? 0.05 : 0.1, longitudeDelta: emptySearch ? 0.05 : 0.1))
        } 
        Task {
            let search = MKLocalSearch(request: request)
            let response = try? await search.start()
            DispatchQueue.main.sync {
                retrievedGyms = response?.mapItems ?? []
                filterGyms()
            }
        }
    }
    
    private func filterGyms() {
        let filtered = searchText.isEmpty ? retrievedGyms : retrievedGyms.filter { gym in
            gym.name?.lowercased().contains(searchText.lowercased()) ?? false
        }
        filteredGyms = filtered.sorted { calculateDistance(to: $0) < calculateDistance(to: $1) }
    }

    func calculateDistance(to gym: MKMapItem) -> Double {
        guard let userLocation = locationManager.location else { return 0 }
        let gymLocation = gym.placemark.coordinate
        let distanceInMeters = userLocation.distance(from: CLLocation(latitude: gymLocation.latitude, longitude: gymLocation.longitude))
        return distanceInMeters * 0.000621371
    }
    func openMaps(latitude: Double, longitude: Double) {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "Gym"
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}
