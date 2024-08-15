import SwiftUI
import CoreLocation
import MapKit

class RunLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = RunLocationManager()
    
    @Published var locationEnabled = false
    @Published var locations: [CLLocation] = []
    @Published var distanceTraveled: Double = 0
    @Published var currentPace: Double = 0
    @Published var paces: [(pace: Double, timestamp: Date)] = []
    
    private var kalmanFilter: KalmanFilter?
    private var locationManager = CLLocationManager()
    private var previousLocation: CLLocation?
    
    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 3
        locationManager.activityType = .fitness
        kalmanFilter = KalmanFilter()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            locationEnabled = false
        case .authorizedAlways, .authorizedWhenInUse:
            locationEnabled = true
            locationManager.allowsBackgroundLocationUpdates = true
        @unknown default:
            locationEnabled = false
        }
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false
        distanceTraveled = 0
        locations = []
        currentPace = 0
        previousLocation = nil
        paces = []
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for newLocation in locations {
            guard newLocation.horizontalAccuracy < 20 else { continue }
            
            let filteredLocation = kalmanFilter?.process(newLocation) ?? newLocation
            
            if let previousLocation = previousLocation {
                let distanceInMeters = filteredLocation.distance(from: previousLocation)
                let distanceInMiles = distanceInMeters * 0.000621371
                distanceTraveled += distanceInMiles
                
                let differenceInHours = filteredLocation.timestamp.timeIntervalSince(previousLocation.timestamp) / 3600
                let speedMPH = distanceInMiles / differenceInHours
                
                if speedMPH > 0.2 {
                    let paceInMinutesPerMile = 60 / speedMPH
                    currentPace = paceInMinutesPerMile
                    paces.append((pace: paceInMinutesPerMile, timestamp: filteredLocation.timestamp))
                }
            }
            self.locations.append(filteredLocation)
            previousLocation = filteredLocation
        }
    }
    
    func calculateAveragePace() -> Double {
        guard !paces.isEmpty else { return 0 }
        let totalPace = paces.map { $0.pace }.reduce(0, +)
        return totalPace / Double(paces.count)
    }
}
class KalmanFilter {
    private var lastEstimate: CLLocation?

    func process(_ newLocation: CLLocation) -> CLLocation {
        guard let lastEstimate = lastEstimate else {
            self.lastEstimate = newLocation
            return newLocation
        }
        
        let alpha = 0.1
        let lat = alpha * newLocation.coordinate.latitude + (1 - alpha) * lastEstimate.coordinate.latitude
        let lon = alpha * newLocation.coordinate.longitude + (1 - alpha) * lastEstimate.coordinate.longitude
        
        let filteredLocation = CLLocation(latitude: lat, longitude: lon)
        self.lastEstimate = filteredLocation
        
        return filteredLocation
    }
}
