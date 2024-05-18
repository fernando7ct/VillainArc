import Foundation
import SwiftData

@Model
class User {
    var id: String
    var name: String
    var dateJoined: Date
    
    init(id: String, name: String, dateJoined: Date) {
        self.id = id
        self.name = name
        self.dateJoined = dateJoined
    }
}
