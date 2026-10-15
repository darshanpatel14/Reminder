import SwiftUI

public struct ContentView: View {
    @StateObject private var scheduler = NotificationScheduler.shared
    @State private var reminders: [Reminder] = []
    @State private var showingAddSheet = false
    @State private var selectedReminderToEdit: Reminder? = nil
    
    private let storageKey = "hourpulse_saved_reminders"
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Top Quiet Night Guardian Banner
                    HStack(spacing: 14) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.indigo)
                            .frame(width: 44, height: 44)
                            .background(Color.indigo.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text("Night Sleep Protection")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Text("Active")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.15))
                                    .foregroundColor(.green)
                                    .clipShape(Capsule())
                            }
                            Text("No alerts will sound between 9:00 PM and 8:30 AM.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
                    
                    // Today's Rings Visual Dial Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Today's Schedule")
                                .font(.headline)
                                .fontWeight(.bold)
                            Spacer()
                            Text("\(totalChimesToday) Chimes Active")
                                .font(.caption.monospaced())
                                .foregroundColor(.cyan)
                        }
                        
                        // 24 Hour Dial Bar
                        HStack(spacing: 3) {
                            ForEach(0..<24, id: \.self) { hour in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(hourColor(for: hour))
                                    .frame(height: 32)
                            }
                        }
                        
                        HStack {
                            Text("12 AM")
                            Spacer()
                            Text("6 AM")
                            Spacer()
                            Text("12 PM")
                            Spacer()
                            Text("6 PM")
                            Spacer()
                            Text("12 AM")
                        }
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    
                    // Reminders List Header
                    HStack {
                        Text("Active Reminders")
                            .font(.headline)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                    
                    // Cards
                    if reminders.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "bell.slash")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("No Hourly Reminders Yet")
                                .font(.headline)
                            Text("Create your first Daytime Hourly reminder.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Button("Create Reminder") {
                                showingAddSheet = true
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.cyan)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 36)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    } else {
                        ForEach($reminders) { $rem in
                            ReminderCardView(
                                reminder: $rem,
                                onEdit: { selectedReminderToEdit = rem },
                                onDelete: { deleteReminder(rem) },
                                onToggle: { _ in updateReminder(rem) },
                                onTest: {
                                    SoundManager.shared.playChime(named: rem.soundName)
                                    scheduler.triggerTestNotification(
                                        title: rem.title,
                                        body: rem.notes.isEmpty ? "Lock iPhone to test sound & Snooze/Stop on lockscreen!" : rem.notes,
                                        emoji: rem.emoji,
                                        soundName: rem.soundName,
                                        delay: 3.0
                                    )
                                },
                                onPauseToday: {
                                    rem.isPausedToday.toggle()
                                    updateReminder(rem)
                                }
                            )
                        }
                    }
                    
                    // Curated Presets
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sober Curated Presets")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            presetButton(title: "1-Min Test", emoji: "⚡️", interval: 1, startH: 0, endH: 23)
                            presetButton(title: "Hydration", emoji: "💧", interval: 60, startH: 9, endH: 21)
                            presetButton(title: "Posture Stretch", emoji: "🧘", interval: 45, startH: 9, endH: 18)
                            presetButton(title: "Eye Rest", emoji: "👁️", interval: 30, startH: 10, endH: 19)
                        }
                    }
                    .padding(.top, 10)
                }
                .padding()
            }
            .navigationTitle("HourPulse")
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        scheduler.clearAllDeliveredNotifications()
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "bell.slash")
                            Text("Clear")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.cyan)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddEditReminderView { newRem in
                    reminders.append(newRem)
                    saveAndReschedule()
                }
            }
            .sheet(item: $selectedReminderToEdit) { remToEdit in
                AddEditReminderView(existingReminder: remToEdit) { updatedRem in
                    if let idx = reminders.firstIndex(where: { $0.id == updatedRem.id }) {
                        reminders[idx] = updatedRem
                        saveAndReschedule()
                    }
                }
            }
            .onAppear {
                loadReminders()
                scheduler.requestAuthorization()
            }
        }
    }
    
    private var totalChimesToday: Int {
        reminders.filter { $0.isEnabled && !$0.isPausedToday }.reduce(0) { $0 + $1.computedScheduleTimes().count }
    }
    
    private func hourColor(for hour: Int) -> Color {
        if hour < 8 || hour >= 22 {
            return Color.blue.opacity(0.1) // Quiet night
        }
        let hasActiveChime = reminders.contains { rem in
            rem.isEnabled && rem.startHour <= hour && rem.endHour >= hour
        }
        return hasActiveChime ? Color.cyan.opacity(0.6) : Color.gray.opacity(0.2)
    }
    
    private func presetButton(title: String, emoji: String, interval: Int, startH: Int, endH: Int) -> some View {
        Button(action: {
            let r = Reminder(title: title, emoji: emoji, intervalMinutes: interval, startHour: startH, endHour: endH)
            reminders.append(r)
            saveAndReschedule()
        }) {
            VStack(alignment: .leading, spacing: 4) {
                Text(emoji).font(.title3)
                Text(title).font(.subheadline.bold()).foregroundColor(.primary)
                Text("\(interval)m • \(startH)AM-\(endH > 12 ? endH - 12 : endH)PM")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
    
    private func loadReminders() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([Reminder].self, from: data) {
            reminders = saved
        } else {
            // Default first reminder
            reminders = [
                Reminder(title: "Hydration & Posture", emoji: "💧", intervalMinutes: 60, startHour: 9, endHour: 21),
                Reminder(title: "Stand & Stretch", emoji: "🧘", intervalMinutes: 45, startHour: 9, endHour: 18, activeDays: [2, 3, 4, 5, 6])
            ]
            saveAndReschedule()
        }
    }
    
    private func updateReminder(_ reminder: Reminder) {
        if let idx = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[idx] = reminder
            saveAndReschedule()
        }
    }
    
    private func deleteReminder(_ reminder: Reminder) {
        reminders.removeAll { $0.id == reminder.id }
        scheduler.cancelReminder(id: reminder.id)
        saveReminders()
    }
    
    private func saveAndReschedule() {
        saveReminders()
        scheduler.rescheduleAll(reminders: reminders)
    }
    
    private func saveReminders() {
        if let data = try? JSONEncoder().encode(reminders) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
