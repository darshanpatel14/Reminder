import Foundation
import UserNotifications
import Combine

/// Manages UNUserNotificationCenter with Windowed Hourly Scheduling,
/// Interactive Snooze / Done Actions, Custom Audible Chimes, and Spam Prevention
public final class NotificationScheduler: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    public static let shared = NotificationScheduler()
    
    @Published public var isAuthorized: Bool = false
    @Published public var pendingCount: Int = 0
    
    public static let categoryIdentifier = "HOURPULSE_REMINDER"
    public static let actionSnooze = "ACTION_SNOOZE_10M"
    public static let actionDone = "ACTION_DONE_STOP"
    
    private let center = UNUserNotificationCenter.current()
    
    private override init() {
        super.init()
        center.delegate = self
        registerNotificationCategories()
        checkAuthorization()
    }
    
    /// Registers interactive notification actions (Snooze & Done/Stop)
    private func registerNotificationCategories() {
        let snoozeAction = UNNotificationAction(
            identifier: Self.actionSnooze,
            title: "Snooze 10m ⏱️",
            options: []
        )
        
        let doneAction = UNNotificationAction(
            identifier: Self.actionDone,
            title: "Done / Stop ✅",
            options: [.destructive]
        )
        
        let reminderCategory = UNNotificationCategory(
            identifier: Self.categoryIdentifier,
            actions: [snoozeAction, doneAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        center.setNotificationCategories([reminderCategory])
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
    
    /// Maps sound names to bundled WAV files
    private func soundFileName(for soundName: String) -> String {
        switch soundName.lowercased() {
        case "bell", "zen_bell":
            return "bell.wav"
        case "water", "raindrop":
            return "water.wav"
        case "singing_bowl":
            return "singing_bowl.wav"
        default:
            return "chime.wav"
        }
    }
    
    /// Schedules windowed hourly triggers for a specific reminder
    public func scheduleReminder(_ reminder: Reminder) {
        cancelReminder(id: reminder.id)
        
        guard reminder.isEnabled && !reminder.isPausedToday else { return }
        
        let times = reminder.computedScheduleTimes()
        let soundFile = soundFileName(for: reminder.soundName)
        let sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: soundFile))
        
        for timeSlot in times {
            guard let hour = timeSlot.hour, let minute = timeSlot.minute else { continue }
            
            for day in reminder.activeDays {
                let content = UNMutableNotificationContent()
                content.title = "\(reminder.emoji) \(reminder.title)"
                content.body = reminder.notes.isEmpty 
                    ? "Hourly reminder (\(formatDeviceTime(hour: hour, minute: minute)))."
                    : reminder.notes
                content.sound = sound
                content.badge = 1
                content.categoryIdentifier = Self.categoryIdentifier
                content.threadIdentifier = "hourpulse-reminders"
                content.userInfo = [
                    "reminderId": reminder.id.uuidString,
                    "title": reminder.title,
                    "emoji": reminder.emoji,
                    "notes": reminder.notes,
                    "soundName": reminder.soundName
                ]
                
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
    
    /// Triggers a single test notification without stacking multiple duplicates
    public func triggerTestNotification(title: String, body: String, emoji: String = "🔔", soundName: String = "chime") {
        let soundFile = soundFileName(for: soundName)
        let sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: soundFile))
        
        let content = UNMutableNotificationContent()
        content.title = "\(emoji) \(title)"
        content.body = body
        content.sound = sound
        content.categoryIdentifier = Self.categoryIdentifier
        content.threadIdentifier = "hourpulse-test"
        content.userInfo = [
            "title": title,
            "emoji": emoji,
            "notes": body,
            "soundName": soundName
        ]
        
        // Remove previous test notifications so they don't pile up in Notification Centre
        center.removeDeliveredNotifications(withIdentifiers: ["hourpulse-single-test-chime"])
        center.removePendingNotificationRequests(withIdentifiers: ["hourpulse-single-test-chime"])
        
        // Single identifier replaces any previous test notification instead of spamming in Notification Centre
        let request = UNNotificationRequest(
            identifier: "hourpulse-single-test-chime",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
        )
        center.add(request)
    }
    
    /// Clears past notifications from the Notification Centre
    public func clearAllDeliveredNotifications() {
        center.removeAllDeliveredNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    public func refreshPendingCount() {
        center.getPendingNotificationRequests { [weak self] requests in
            DispatchQueue.main.async {
                self?.pendingCount = requests.count
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    /// Show banner and play sound even when app is open in foreground
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        let soundName = userInfo["soundName"] as? String ?? "chime"
        SoundManager.shared.playChime(named: soundName)
        completionHandler([.banner, .sound, .badge, .list])
    }
    
    /// Handles user interaction with Snooze and Done/Stop actions
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let title = userInfo["title"] as? String ?? "Reminder"
        let emoji = userInfo["emoji"] as? String ?? "🔔"
        let notes = userInfo["notes"] as? String ?? ""
        let soundName = userInfo["soundName"] as? String ?? "chime"
        
        switch response.actionIdentifier {
        case Self.actionSnooze:
            // Snooze for 10 minutes: schedule a one-off notification in 10 minutes
            let snoozeContent = UNMutableNotificationContent()
            snoozeContent.title = "\(emoji) Snooze: \(title)"
            snoozeContent.body = notes.isEmpty ? "Snoozed reminder is due now." : notes
            let soundFile = soundFileName(for: soundName)
            snoozeContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: soundFile))
            snoozeContent.categoryIdentifier = Self.categoryIdentifier
            snoozeContent.threadIdentifier = "hourpulse-reminders"
            snoozeContent.userInfo = userInfo
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 600, repeats: false) // 10 minutes
            let snoozeRequest = UNNotificationRequest(
                identifier: "hourpulse-snooze-\(UUID().uuidString)",
                content: snoozeContent,
                trigger: trigger
            )
            center.add(snoozeRequest)
            
            DispatchQueue.main.async {
                SoundManager.shared.speakVoicePrompt("Snoozed for 10 minutes")
            }
            
        case Self.actionDone:
            // Done / Stop for this hour: clear badge and dismiss.
            // Next scheduled hour will still chime normally on schedule!
            UIApplication.shared.applicationIconBadgeNumber = 0
            DispatchQueue.main.async {
                SoundManager.shared.speakVoicePrompt("Reminder completed")
            }
            
        default:
            break
        }
        
        completionHandler()
    }
    
    /// Formats time respecting the user's iPhone default 12-hour or 24-hour setting
    public func formatDeviceTime(hour: Int, minute: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        
        let calendar = Calendar.current
        if let date = calendar.date(from: components) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.locale = Locale.current
            return formatter.string(from: date)
        }
        
        let period = hour >= 12 ? "PM" : "AM"
        let dh = hour % 12 == 0 ? 12 : hour % 12
        return String(format: "%d:%02d %@", dh, minute, period)
    }
}
