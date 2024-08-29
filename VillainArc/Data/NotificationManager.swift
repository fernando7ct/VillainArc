import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private(set) var notificationsAllowed = false
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error)")
            } else {
                self.notificationsAllowed = granted
                print("Notifications Enabled: \(granted)")
            }
        }
    }
    
    func scheduleNotification(title: String, body: String, timeInterval: TimeInterval) {
        guard notificationsAllowed else {
            print("Notifications are not allowed.")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func removeAllNotifications() {
        guard notificationsAllowed else {
            print("Notifications are not allowed.")
            return
        }
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("All notifications removed")
    }
}
