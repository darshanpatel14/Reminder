import SwiftUI

public struct ReminderCardView: View {
    @Binding var reminder: Reminder
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onToggle: (Bool) -> Void
    var onTest: () -> Void
    var onPauseToday: () -> Void
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header Row: Emoji, Title, Badges, and Toggle Switch
            HStack(alignment: .top, spacing: 12) {
                Text(reminder.emoji)
                    .font(.system(size: 26))
                    .frame(width: 44, height: 44)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(reminder.isEnabled ? .primary : .secondary)
                    
                    // Metadata Badges Row
                    HStack(spacing: 6) {
                        Text(reminder.frequencyDescription)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.cyan.opacity(0.15))
                            .foregroundColor(.cyan)
                            .clipShape(Capsule())
                        
                        Text(reminder.timeWindowDescription)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(.tertiarySystemBackground))
                            .foregroundColor(.secondary)
                            .clipShape(Capsule())
                        
                        Text(reminder.daysDescription)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(.tertiarySystemBackground))
                            .foregroundColor(.secondary)
                            .clipShape(Capsule())
                    }
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { reminder.isEnabled },
                    set: { newVal in
                        reminder.isEnabled = newVal
                        onToggle(newVal)
                    }
                ))
                .labelsHidden()
                .tint(.green)
            }
            
            // Visual Ring Dots Row
            let times = reminder.computedScheduleTimes()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(0..<min(times.count, 14), id: \.self) { i in
                        Circle()
                            .fill(reminder.isEnabled ? Color.cyan.opacity(0.35) : Color.gray.opacity(0.2))
                            .frame(width: 8, height: 8)
                    }
                    if times.count > 14 {
                        Text("+\(times.count - 14)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 2)
            }
            
            Divider()
                .background(Color.white.opacity(0.08))
            
            // Bottom Action Bar
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "bell.badge.fill")
                        .font(.caption2)
                        .foregroundColor(.cyan)
                    Text("\(times.count) Chimes / Day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: onTest) {
                        Text("Test 🔔")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(Capsule())
                    }
                    
                    Button(action: onPauseToday) {
                        Text(reminder.isPausedToday ? "Resume ▶️" : "Pause ⏸️")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(reminder.isPausedToday ? Color.orange.opacity(0.2) : Color(.tertiarySystemBackground))
                            .foregroundColor(reminder.isPausedToday ? .orange : .primary)
                            .clipShape(Capsule())
                    }
                    
                    Menu {
                        Button(action: onEdit) {
                            Label("Edit Reminder", systemImage: "pencil")
                        }
                        Button(role: .destructive, action: onDelete) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.caption)
                            .padding(8)
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(reminder.isPausedToday ? Color.orange.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 1)
        )
        .opacity(reminder.isEnabled ? 1.0 : 0.6)
    }
}
