import Foundation
import UserNotifications
import Combine

/// Manages UNUserNotificationCenter with Windowed Hourly Scheduling
public final class NotificationScheduler: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    public static let shared = NotificationScheduler()
    
    @Published public var isAuthorized: Bool = false
    @Published public var pendingCount: Int = 0
    
    private let center = UNUserNotificationCenter.current()
    
    private override init() {
        super.init()
        center.delegate = self
        checkAuthorization()
    }
    
    /// Requests notification permissions from iOS
    public func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                completion?(granted)
            }
        }
    }
    
    public func checkAuthorization() {
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = (settings.authorizationStatus == .authorized)
            }
        }
    }
    
    /// Schedules windowed hourly triggers for a specific reminder
    public func scheduleReminder(_ reminder: Reminder) {
        // First cancel any existing notifications for this reminder
        cancelReminder(id: reminder.id)
        
        guard reminder.isEnabled && !reminder.isPausedToday else { return }
        
        let times = reminder.computedScheduleTimes()
        let sound = UNNotificationSound.default
        
        // Loop through each calculated time slot inside the daytime window
        for (index, timeSlot) in times.enumerated() {
            guard let hour = timeSlot.hour, let minute = timeSlot.minute else { continue }
            
            // Loop through selected active days
            for day in reminder.activeDays {
                let content = UNMutableNotificationContent()
                content.title = "\(reminder.emoji) \(reminder.title)"
                content.body = reminder.notes.isEmpty 
                    ? "Hourly reminder scheduled for \(formatTime(hour: hour, minute: minute))." 
                    : reminder.notes
                content.sound = sound
                content.badge = 1
                content.userInfo = ["reminderId": reminder.id.uuidString]
                
                var dateComponents = DateComponents()
                dateComponents.hour = hour
                dateComponents.minute = minute
                dateComponents.weekday = day
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let identifier = "hourpulse-\(reminder.id.uuidString)-d\(day)-h\(hour)m\(minute)"
                
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                center.add(request) { error in
                    if let error = error {
                        print("Error adding notification request: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        refreshPendingCount()
    }
    
    /// Cancels all scheduled triggers belonging to a reminder
    public func cancelReminder(id: UUID) {
        let prefix = "hourpulse-\(id.uuidString)"
        center.getPendingNotificationRequests { [weak self] requests in
            let matchingIds = requests.filter { $0.identifier.hasPrefix(prefix) }.map { $0.identifier }
            self?.center.removePendingNotificationRequests(withIdentifiers: matchingIds)
            self?.refreshPendingCount()
        }
    }
    
    /// Reschedules all enabled reminders
    public func rescheduleAll(reminders: [Reminder]) {
        center.removeAllPendingNotificationRequests()
        for rem in reminders where rem.isEnabled {
            scheduleReminder(rem)
        }
        refreshPendingCount()
    }
    
    /// Triggers a test notification immediately (5 seconds delayed)
    public func triggerTestNotification(title: String, body: String, emoji: String = "🔔") {
        let content = UNMutableNotificationContent()
        content.title = "\(emoji) \(title)"
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        center.add(request)
    }
    
    public func refreshPendingCount() {
        center.getPendingNotificationRequests { [weak self] requests in
            DispatchQueue.main.async {
                self?.pendingCount = requests.count
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner and play sound even when app is open in foreground!
        completionHandler([.banner, .sound, .badge])
    }
    
    private func formatTime(hour: Int, minute: Int) -> String {
        let period = hour >= 12 ? "PM" : "AM"
        let displayH = hour % 12 == 0 ? 12 : hour % 12
        let displayM = String(format: "%02d", minute)
        return "\(displayH):\(displayM) \(period)"
    }
}
