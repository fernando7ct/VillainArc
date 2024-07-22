import SwiftUI
import SwiftData
import CoreLocation

@Model
class Gym {
    var id: String = UUID().uuidString
    var name: String
    var address: String
    var phoneNumber: String?
    var url: URL?
    var latitude: Double
    var longitude: Double
    
    init(id: String, name: String, address: String, phoneNumber: String?, url: URL?, latitude: Double, longitude: Double) {
        self.id = id
        self.name = name
        self.address = address
        self.phoneNumber = phoneNumber
        self.url = url
        self.latitude = latitude
        self.longitude = longitude
    }
    
    var coordinate: CLLocationCoordinate2D {
        .init(latitude: latitude, longitude: longitude)
    }
}
