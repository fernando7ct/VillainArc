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

    init(id: String = UUID().uuidString, name: String, dateJoined: Date, birthday: Date, heightFeet: Int, heightInches: Int, sex: String) {
        self.id = id
        self.name = name
        self.dateJoined = dateJoined
        self.birthday = birthday
        self.heightFeet = heightFeet
        self.heightInches = heightInches
        self.sex = sex
    }
}

extension User {
    func toDictionary() -> [String: Any] {
        return [
            "id": self.id,
            "name": self.name,
            "dateJoined": self.dateJoined,
            "birthday": self.birthday,
            "heightFeet": self.heightFeet,
            "heightInches": self.heightInches,
            "sex": self.sex
        ]
    }
}
