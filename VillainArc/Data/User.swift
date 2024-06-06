import Foundation
import SwiftData

@Model
class User {
    var id: String = UUID().uuidString
    var name: String = ""
    var dateJoined: Date = Date()
    
    init(id: String, name: String, dateJoined: Date) {
        self.id = id
        self.name = name
        self.dateJoined = dateJoined
    }
}
