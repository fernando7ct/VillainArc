import SwiftUI
import SwiftData
import MapKit

@Model
class Gym {
    var id: String = UUID().uuidString
    var name: String = ""
    var address: String = ""
    var latitude: Double = 0
    var longitude: Double = 0
    var favorite: Bool = false
    
    init(id: String, name: String, address: String, latitude: Double, longitude: Double, favorite: Bool) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.favorite = favorite
    }
    init(id: String, mapItem: MKMapItem, favorite: Bool) {
        self.id = id
        self.name = mapItem.name ?? ""
        self.address = mapItem.placemark.title ?? ""
        self.latitude = mapItem.placemark.coordinate.latitude
        self.longitude = mapItem.placemark.coordinate.longitude
        self.favorite = favorite
    }
}
extension Gym {
    func toDictionary() -> [String: Any] {
        return [
            "id": self.id,
            "name": self.name,
            "address": self.address,
            "latitude": self.latitude,
            "longitude": self.longitude,
            "favorite": self.favorite
        ]
    }
}
