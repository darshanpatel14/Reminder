import SwiftUI

public struct AddEditReminderView: View {
    @Environment(\.dismiss) private var dismiss
    
    var existingReminder: Reminder?
    var onSave: (Reminder) -> Void
    
    @State private var title: String = ""
    @State private var emoji: String = "💧"
    @State private var intervalMinutes: Int = 60
    @State private var startDate: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    @State private var endDate: Date = Calendar.current.date(from: DateComponents(hour: 21, minute: 0)) ?? Date()
    @State private var activeDays: Set<Int> = [1, 2, 3, 4, 5, 6, 7]
    @State private var soundName: String = "zen_bell"
    @State private var notes: String = ""
    @State private var isCustomInterval: Bool = false
    @State private var customMinutesString: String = "90"
    
    let emojiOptions = ["💧", "🧘", "👁️", "🌿", "🎯", "💊", "🚶", "☕"]
    let intervalOptions = [15, 30, 45, 60, 120]
    
    public init(existingReminder: Reminder? = nil, onSave: @escaping (Reminder) -> Void) {
        self.existingReminder = existingReminder
        self.onSave = onSave
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                // Section 1: Title & Icon
                Section("Reminder Info") {
                    HStack(spacing: 12) {
                        Menu {
                            ForEach(emojiOptions, id: \.self) { em in
                                Button(em) { emoji = em }
                            }
                        } label: {
                            Text(emoji)
                                .font(.system(size: 28))
                                .frame(width: 44, height: 44)
                                .background(Color(.tertiarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        
                        TextField("e.g. Drink Water & Posture", text: $title)
                            .font(.body)
                    }
                    
                    TextField("Notes (optional)", text: $notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Section 2: Frequency
                Section("Frequency & Interval") {
                    Picker("Interval", selection: $intervalMinutes) {
                        Text("1m ⚡️").tag(1)
                        Text("15m").tag(15)
                        Text("30m").tag(30)
                        Text("45m").tag(45)
                        Text("1 Hr").tag(60)
                        Text("2 Hr").tag(120)
                    }
                    .pickerStyle(.segmented)
                    
                    if intervalMinutes == 1 {
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.orange)
                            Text("1-Minute Test Mode: Chimes every 60s even when iPhone is locked or app is closed. Perfect for testing!")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        .padding(.vertical, 2)
                    }
                }
                
                // Section 3: The Active Time Window (The Core Innovation)
                Section(header: Text("Active Time Window (Quiet Night Safe)"), footer: Text("Zero notifications will ring outside this window. Your sleep will never be disturbed.")) {
                    DatePicker("Starts at", selection: $startDate, displayedComponents: .hourAndMinute)
                    DatePicker("Ends at", selection: $endDate, displayedComponents: .hourAndMinute)
                    
                    HStack {
                        Button("9 AM – 9 PM") {
                            setWindow(startH: 9, startM: 0, endH: 21, endM: 0)
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                        
                        Button("9 AM – 6 PM") {
                            setWindow(startH: 9, startM: 0, endH: 18, endM: 0)
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                        
                        Button("8 AM – 10 PM") {
                            setWindow(startH: 8, startM: 0, endH: 22, endM: 0)
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                    }
                }
                
                // Section 4: Active Days
                Section("Active Days") {
                    HStack {
                        if activeDays.count == 7 {
                            Button("Daily") { activeDays = [1, 2, 3, 4, 5, 6, 7] }
                                .buttonStyle(.borderedProminent)
                                .font(.caption)
                        } else {
                            Button("Daily") { activeDays = [1, 2, 3, 4, 5, 6, 7] }
                                .buttonStyle(.bordered)
                                .font(.caption)
                        }
                        
                        if activeDays == [2, 3, 4, 5, 6] {
                            Button("Weekdays") { activeDays = [2, 3, 4, 5, 6] }
                                .buttonStyle(.borderedProminent)
                                .font(.caption)
                        } else {
                            Button("Weekdays") { activeDays = [2, 3, 4, 5, 6] }
                                .buttonStyle(.bordered)
                                .font(.caption)
                        }
                        
                        if activeDays == [1, 7] {
                            Button("Weekends") { activeDays = [1, 7] }
                                .buttonStyle(.borderedProminent)
                                .font(.caption)
                        } else {
                            Button("Weekends") { activeDays = [1, 7] }
                                .buttonStyle(.bordered)
                                .font(.caption)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        let days = [
                            (1, "S"), (2, "M"), (3, "T"), (4, "W"), (5, "T"), (6, "F"), (7, "S")
                        ]
                        ForEach(days, id: \.0) { dayNum, label in
                            let isSelected = activeDays.contains(dayNum)
                            Button(action: {
                                if isSelected {
                                    if activeDays.count > 1 { activeDays.remove(dayNum) }
                                } else {
                                    activeDays.insert(dayNum)
                                }
                            }) {
                                Text(label)
                                    .font(.caption.bold())
                                    .frame(width: 34, height: 34)
                                    .background(isSelected ? Color.cyan : Color(.tertiarySystemBackground))
                                    .foregroundColor(isSelected ? .black : .primary)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Section 5: Chime Sound Selection with Preview
                Section("Chime Sound") {
                    Picker("Sound Tone", selection: $soundName) {
                        Text("Zen Bell 🔔").tag("zen_bell")
                        Text("Chime 🎶").tag("chime")
                        Text("Singing Bowl 🥣").tag("singing_bowl")
                        Text("Raindrop 💧").tag("water")
                    }
                    .pickerStyle(.menu)
                    
                    Button(action: {
                        SoundManager.shared.playPreview(named: soundName)
                    }) {
                        HStack {
                            Image(systemName: "speaker.wave.2.fill")
                            Text("Preview Sound Tone")
                        }
                        .font(.subheadline)
                        .foregroundColor(.cyan)
                    }
                }
                
                // Section 6: Computed Schedule Preview
                let previewTimes = computePreviewTimes()
                Section("Generated Daily Schedule (\(previewTimes.count) Chimes)") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(previewTimes, id: \.self) { timeStr in
                                Text(timeStr)
                                    .font(.caption2.monospaced())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.tertiarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                }
            }
            .navigationTitle(existingReminder == nil ? "New Reminder" : "Edit Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .tint(.cyan)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear(perform: loadExistingData)
        }
    }
    
    private func setWindow(startH: Int, startM: Int, endH: Int, endM: Int) {
        if let s = Calendar.current.date(from: DateComponents(hour: startH, minute: startM)) {
            startDate = s
        }
        if let e = Calendar.current.date(from: DateComponents(hour: endH, minute: endM)) {
            endDate = e
        }
    }
    
    private func loadExistingData() {
        guard let rem = existingReminder else { return }
        title = rem.title
        emoji = rem.emoji
        intervalMinutes = rem.intervalMinutes
        notes = rem.notes
        activeDays = rem.activeDays
        soundName = rem.soundName
        setWindow(startH: rem.startHour, startM: rem.startMinute, endH: rem.endHour, endM: rem.endMinute)
    }
    
    private func computePreviewTimes() -> [String] {
        let cal = Calendar.current
        let sComp = cal.dateComponents([.hour, .minute], from: startDate)
        let eComp = cal.dateComponents([.hour, .minute], from: endDate)
        
        let startMins = (sComp.hour ?? 9) * 60 + (sComp.minute ?? 0)
        var endMins = (eComp.hour ?? 21) * 60 + (eComp.minute ?? 0)
        if endMins <= startMins { endMins = 24 * 60 }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        
        var list: [String] = []
        var cur = startMins
        let step = max(1, intervalMinutes)
        while cur <= endMins && list.count < 30 {
            let h = cur / 60
            let m = cur % 60
            if let date = cal.date(from: DateComponents(hour: h, minute: m)) {
                list.append(formatter.string(from: date))
            } else {
                let period = h >= 12 ? "PM" : "AM"
                let dh = h % 12 == 0 ? 12 : h % 12
                list.append(String(format: "%d:%02d %@", dh, m, period))
            }
            cur += step
        }
        if list.count == 30 && cur <= endMins {
            list.append("...")
        }
        return list
    }
    
    private func save() {
        let cal = Calendar.current
        let sComp = cal.dateComponents([.hour, .minute], from: startDate)
        let eComp = cal.dateComponents([.hour, .minute], from: endDate)
        
        let rem = Reminder(
            id: existingReminder?.id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            emoji: emoji,
            intervalMinutes: intervalMinutes,
            startHour: sComp.hour ?? 9,
            startMinute: sComp.minute ?? 0,
            endHour: eComp.hour ?? 21,
            endMinute: eComp.minute ?? 0,
            activeDays: activeDays,
            soundName: soundName,
            isEnabled: existingReminder?.isEnabled ?? true,
            isPausedToday: existingReminder?.isPausedToday ?? false,
            notes: notes
        )
        onSave(rem)
    }
}
