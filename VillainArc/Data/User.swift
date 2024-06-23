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
    
    init(id: String, name: String, dateJoined: Date, birthday: Date, heightFeet: Int, heightInches: Int) {
        self.id = id
        self.name = name
        self.dateJoined = dateJoined
        self.birthday = birthday
        self.heightFeet = heightFeet
        self.heightInches = heightInches
    }
}
