import SwiftUI
import CoreLocation

class RunLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var locationEnabled = false
    @Published var distanceTraveled: Double = 0
    @Published var currentPace: Double = 0
    @Published var averagePace: Double = 0
    @Published var paces: [(time: Date, pace: Double)] = []
    @Published var milePaces: [(mile: Double, pace: Double)] = []
    
    private var locationManager = CLLocationManager()
    private var previousLocation: CLLocation?
    
    private var lastMileMarker: Double = 0
    private var startTimeForCurrentMile: Date = Date()
    
    private var lastPaceUpdateDistance: Double = 0
    private var lastAveragePaceUpdateDistance: Double = 0
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .fitness
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            locationEnabled = false
            locationManager.stopUpdatingLocation()
        case .authorizedAlways, .authorizedWhenInUse:
            locationEnabled = true
        @unknown default:
            locationEnabled = false
            locationManager.stopUpdatingLocation()
        }
    }
    func startRun() {
        startTimeForCurrentMile = Date()
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = true
    }
    
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false
        previousLocation = nil
    }
    func finishRun() {
        stopTracking()
        averagePace = calculateAveragePace()
        let distance = distanceTraveled - lastMileMarker
        let time = Date().timeIntervalSince(startTimeForCurrentMile)
        let minutes = time / 60
        let pace = minutes / distance
        milePaces.append((mile: distanceTraveled, pace: pace))
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for newLocation in locations {
            guard newLocation.horizontalAccuracy < 20 else { continue }
            
            if let previous = previousLocation {
                let distanceInMeters = newLocation.distance(from: previous)
                let timeDifference = newLocation.timestamp.timeIntervalSince(previous.timestamp)
                let speedMetersPerSecond = distanceInMeters / timeDifference
                
                guard speedMetersPerSecond < 6.7 else { continue }
                
                let distanceInMiles = distanceInMeters / 1609.34
                distanceTraveled += distanceInMiles
                previousLocation = newLocation
                
                // Check if the user has completed another mile
                let totalMilesCompleted = floor(distanceTraveled)
                if totalMilesCompleted > lastMileMarker {
                    let timeForCurrentMile = Date().timeIntervalSince(startTimeForCurrentMile)
                    let paceForMile = timeForCurrentMile / 60
                    lastMileMarker += 1
                    milePaces.append((mile: lastMileMarker, pace: paceForMile))
                    startTimeForCurrentMile = .now
                }
                
                // Update current pace
                if distanceTraveled - lastPaceUpdateDistance >= 0.01 {
                    let distance = distanceTraveled - lastPaceUpdateDistance
                    var time = startTimeForCurrentMile
                    if let lastPace = paces.last {
                        time = lastPace.time
                    }
                    let timeDifference = Date().timeIntervalSince(time)
                    let minutes = timeDifference / 60
                    let pace = minutes / distance
                    
                    let averagedPace = calculateWeightedPace(pace)
                    paces.append((time: .now, pace: pace))
                    lastPaceUpdateDistance = distanceTraveled
                    currentPace = averagedPace
                }
                // Update Average Pace
                if distanceTraveled - lastAveragePaceUpdateDistance >= 0.07 {
                    averagePace = calculateAveragePace()
                    lastAveragePaceUpdateDistance = distanceTraveled
                }
            } else {
                previousLocation = newLocation
            }
        }
    }
    private func calculateWeightedPace(_ pace: Double) -> Double {
        let weightNewPace: Double = 0.7
        let weightLastPace: Double = 0.3
        
        if let lastPace = paces.last?.pace {
            return (pace * weightNewPace) + (lastPace * weightLastPace)
        } else {
            return pace
        }
    }
    private func calculateAveragePace() -> Double {
        let totalPace = paces.map { $0.pace }.reduce(0, +)
        return totalPace / Double(paces.count)
    }
}
