import Foundation

/// Represents an Hourly / Periodic Reminder with Quiet-Night Windows
public struct Reminder: Identifiable, Codable, Equatable {
    public var id: UUID
    public var title: String
    public var emoji: String
    public var intervalMinutes: Int
    public var startHour: Int        // 0 - 23 (e.g. 9 for 09:00 AM)
    public var startMinute: Int      // 0 - 59
    public var endHour: Int          // 0 - 23 (e.g. 21 for 09:00 PM)
    public var endMinute: Int        // 0 - 59
    public var activeDays: Set<Int>  // 1 = Sunday, 2 = Monday ... 7 = Saturday (Apple Calendar convention)
    public var soundName: String
    public var isEnabled: Bool
    public var isPausedToday: Bool
    public var notes: String
    
    public init(
        id: UUID = UUID(),
        title: String,
        emoji: String = "💧",
        intervalMinutes: Int = 60,
        startHour: Int = 9,
        startMinute: Int = 0,
        endHour: Int = 21,
        endMinute: Int = 0,
        activeDays: Set<Int> = [1, 2, 3, 4, 5, 6, 7],
        soundName: String = "zen_bell",
        isEnabled: Bool = true,
        isPausedToday: Bool = false,
        notes: String = ""
    ) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.intervalMinutes = intervalMinutes
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.activeDays = activeDays
        self.soundName = soundName
        self.isEnabled = isEnabled
        self.isPausedToday = isPausedToday
        self.notes = notes
    }
    
    /// Formatted frequency string (e.g., "Every 1 Hour" or "Every 45 mins")
    public var frequencyDescription: String {
        if intervalMinutes >= 60 && intervalMinutes % 60 == 0 {
            let hours = intervalMinutes / 60
            return hours == 1 ? "Every 1 Hour" : "Every \(hours) Hours"
        }
        return "Every \(intervalMinutes) mins"
    }
    
    /// Formatted active window string (e.g., "9:00 AM – 9:00 PM")
    public var timeWindowDescription: String {
        return "\(formatTime(hour: startHour, minute: startMinute)) – \(formatTime(hour: endHour, minute: endMinute))"
    }
    
    /// Formatted active days string
    public var daysDescription: String {
        if activeDays.count == 7 {
            return "Daily"
        } else if activeDays == [2, 3, 4, 5, 6] {
            return "Weekdays"
        } else if activeDays == [1, 7] {
            return "Weekends"
        } else {
            let daySymbols = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            return activeDays.sorted().compactMap { daySymbols[$0] }.joined(separator: ", ")
        }
    }
    
    /// Calculates all trigger times for today within the active window
    public func computedScheduleTimes() -> [DateComponents] {
        var results: [DateComponents] = []
        let startTotalMins = startHour * 60 + startMinute
        var endTotalMins = endHour * 60 + endMinute
        if endTotalMins <= startTotalMins {
            endTotalMins = 24 * 60
        }
        
        let interval = max(5, intervalMinutes)
        var current = startTotalMins
        while current <= endTotalMins {
            let h = current / 60
            let m = current % 60
            results.append(DateComponents(hour: h, minute: m))
            current += interval
        }
        return results
    }
    
    private func formatTime(hour: Int, minute: Int) -> String {
        var comp = DateComponents()
        comp.hour = hour
        comp.minute = minute
        if let date = Calendar.current.date(from: comp) {
            let df = DateFormatter()
            df.timeStyle = .short
            df.locale = Locale.current
            return df.string(from: date)
        }
        let period = hour >= 12 ? "PM" : "AM"
        let displayH = hour % 12 == 0 ? 12 : hour % 12
        let displayM = String(format: "%02d", minute)
        return "\(displayH):\(displayM) \(period)"
    }
}
