import Foundation
import SwiftData

@Model
class User {
    var id: String = UUID().uuidString
    var name: String = ""
    var dateJoined: Date = Date()
    var birthday: Date = Date()
    var heightFeet: Int = 0
    var heightInches: Int = 0
    var sex: String = ""
    var homeGymName: String?
    var homeGymAddress: String?
    var homeGymLatitude: Double?
    var homeGymLongitude: Double?

    init(id: String, name: String, dateJoined: Date, birthday: Date, heightFeet: Int, heightInches: Int, sex: String, homeGymName: String? = nil, homeGymAddress: String? = nil, homeGymLatitude: Double? = nil, homeGymLongitude: Double? = nil) {
        self.id = id
        self.name = name
        self.dateJoined = dateJoined
        self.birthday = birthday
        self.heightFeet = heightFeet
        self.heightInches = heightInches
        self.sex = sex
        self.homeGymName = homeGymName
        self.homeGymAddress = homeGymAddress
        self.homeGymLatitude = homeGymLatitude
        self.homeGymLongitude = homeGymLongitude
    }
}
extension User {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": self.id,
            "name": self.name,
            "dateJoined": self.dateJoined,
            "birthday": self.birthday,
            "heightFeet": self.heightFeet,
            "heightInches": self.heightInches,
            "sex": self.sex
        ]
        if let homeGymName = self.homeGymName {
            dict["homeGymName"] = homeGymName
        }
        if let homeGymAddress = self.homeGymAddress {
            dict["homeGymAddress"] = homeGymAddress
        }
        if let homeGymLatitude = self.homeGymLatitude {
            dict["homeGymLatitude"] = homeGymLatitude
        }
        if let homeGymLongitude = self.homeGymLongitude {
            dict["homeGymLongitude"] = homeGymLongitude
        }
        return dict
    }
}
