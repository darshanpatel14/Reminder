/**
 * HourPulse — Daily Hourly Reminder for iPhone
 * Client Engine: Scheduling, Audio Synthesis, UI State, Local Notifications
 */

(() => {
  'use strict';

  // --- Configuration & Default Presets ---
  const STORAGE_KEY = 'hourpulse_reminders_v1';
  const SETTINGS_KEY = 'hourpulse_settings_v1';

  const DEFAULT_REMINDERS = [
    {
      id: 'rem-1',
      title: 'Hydration & Posture',
      emoji: '💧',
      intervalMinutes: 60,
      startTime: '09:00',
      endTime: '21:00',
      days: [0, 1, 2, 3, 4, 5, 6], // All days
      sound: 'zen_bell',
      enabled: true,
      pausedToday: false,
      notes: 'Take 3 sips of water and roll shoulders back.'
    },
    {
      id: 'rem-2',
      title: 'Stand & Stretch',
      emoji: '🧘',
      intervalMinutes: 45,
      startTime: '09:30',
      endTime: '18:30',
      days: [1, 2, 3, 4, 5], // Mon-Fri
      sound: 'bamboo',
      enabled: true,
      pausedToday: false,
      notes: 'Stand up, stretch legs and decompress spine.'
    },
    {
      id: 'rem-3',
      title: '20-20-20 Eye Rest',
      emoji: '👁️',
      intervalMinutes: 30,
      startTime: '10:00',
      endTime: '19:00',
      days: [1, 2, 3, 4, 5], // Mon-Fri
      sound: 'crystal',
      enabled: false,
      pausedToday: false,
      notes: 'Look 20 feet away for 20 seconds.'
    },
    {
      id: 'rem-4',
      title: 'Deep Mindful Breath',
      emoji: '🌿',
      intervalMinutes: 120,
      startTime: '08:00',
      endTime: '22:00',
      days: [0, 1, 2, 3, 4, 5, 6],
      sound: 'singing_bowl',
      enabled: true,
      pausedToday: false,
      notes: 'Inhale for 4s, hold for 4s, exhale for 6s.'
    }
  ];

  const CURATED_TEMPLATES = [
    { title: 'Hydration & Water', emoji: '💧', interval: 60, start: '09:00', end: '21:00', days: 'daily', sound: 'zen_bell' },
    { title: 'Posture & Ergonomics', emoji: '🧘', interval: 45, start: '09:00', end: '18:00', days: 'weekdays', sound: 'bamboo' },
    { title: 'Eye Rest 20-20-20', emoji: '👁️', interval: 30, start: '10:00', end: '18:00', days: 'weekdays', sound: 'crystal' },
    { title: 'Mindful Breathing', emoji: '🌿', interval: 120, start: '08:00', end: '22:00', days: 'daily', sound: 'singing_bowl' },
    { title: 'Focus Alignment Check', emoji: '🎯', interval: 60, start: '09:00', end: '17:00', days: 'weekdays', sound: 'zen_bell' },
    { title: 'Vitamins & Health', emoji: '💊', interval: 240, start: '08:00', end: '20:00', days: 'daily', sound: 'raindrop' }
  ];

  // State
  let reminders = [];
  let currentFilter = 'all';
  let audioContext = null;
  let editingReminderId = null;
  let lastCheckedMinute = -1;

  // --- Sound Synthesizer (Zero external audio files needed) ---
  function getAudioContext() {
    if (!audioContext) {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      if (AudioCtx) {
        audioContext = new AudioCtx();
      }
    }
    if (audioContext && audioContext.state === 'suspended') {
      audioContext.resume();
    }
    return audioContext;
  }

  function playChime(soundType = 'zen_bell') {
    const ctx = getAudioContext();
    if (!ctx) return;

    const now = ctx.currentTime;

    switch (soundType) {
      case 'singing_bowl': {
        // Dual harmonic rich singing bowl
        [528, 532, 1056].forEach((freq, idx) => {
          const osc = ctx.createOscillator();
          const gain = ctx.createGain();
          osc.type = 'sine';
          osc.frequency.setValueAtTime(freq, now);

          const vol = idx === 0 ? 0.35 : 0.15;
          gain.gain.setValueAtTime(0, now);
          gain.gain.linearRampToValueAtTime(vol, now + 0.05);
          gain.gain.exponentialRampToValueAtTime(0.0001, now + 3.8);

          osc.connect(gain);
          gain.connect(ctx.destination);
          osc.start(now);
          osc.stop(now + 3.8);
        });
        break;
      }

      case 'bamboo': {
        // Snappy organic woodblock / bamboo pop
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(820, now);
        osc.frequency.exponentialRampToValueAtTime(320, now + 0.12);

        gain.gain.setValueAtTime(0.4, now);
        gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.25);

        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(now);
        osc.stop(now + 0.25);
        break;
      }

      case 'crystal': {
        // Sparkling high chime
        [1320, 1980, 2640].forEach((freq, i) => {
          const osc = ctx.createOscillator();
          const gain = ctx.createGain();
          osc.type = 'sine';
          osc.frequency.setValueAtTime(freq, now + i * 0.06);

          gain.gain.setValueAtTime(0.2, now + i * 0.06);
          gain.gain.exponentialRampToValueAtTime(0.0001, now + i * 0.06 + 1.8);

          osc.connect(gain);
          gain.connect(ctx.destination);
          osc.start(now + i * 0.06);
          osc.stop(now + i * 0.06 + 1.8);
        });
        break;
      }

      case 'raindrop': {
        // Gentle droplet pop
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(600, now);
        osc.frequency.exponentialRampToValueAtTime(1400, now + 0.08);

        gain.gain.setValueAtTime(0.3, now);
        gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.35);

        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(now);
        osc.stop(now + 0.35);
        break;
      }

      case 'zen_bell':
      default: {
        // Soothing Zen Temple Bell (432 Hz master)
        [432, 864, 1296].forEach((freq, i) => {
          const osc = ctx.createOscillator();
          const gain = ctx.createGain();
          osc.type = 'sine';
          osc.frequency.setValueAtTime(freq, now);

          const volume = i === 0 ? 0.4 : 0.12;
          gain.gain.setValueAtTime(0, now);
          gain.gain.linearRampToValueAtTime(volume, now + 0.02);
          gain.gain.exponentialRampToValueAtTime(0.0001, now + 2.8);

          osc.connect(gain);
          gain.connect(ctx.destination);
          osc.start(now);
          osc.stop(now + 2.8);
        });
        break;
      }
    }
  }

  // --- Persistence ---
  function loadReminders() {
    try {
      const data = localStorage.getItem(STORAGE_KEY);
      if (data) {
        reminders = JSON.parse(data);
      } else {
        reminders = [...DEFAULT_REMINDERS];
        saveReminders();
      }
    } catch (e) {
      reminders = [...DEFAULT_REMINDERS];
    }
  }

  function saveReminders() {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(reminders));
    } catch (e) {
      console.error('Error saving reminders:', e);
    }
  }

  // --- Date & Time Calculation Engine ---
  function parseTimeToMinutes(timeStr) {
    if (!timeStr) return 0;
    const [h, m] = timeStr.split(':').map(Number);
    return (h || 0) * 60 + (m || 0);
  }

  function formatMinutesToTime(totalMins) {
    const h = Math.floor(totalMins / 60) % 24;
    const m = totalMins % 60;
    const period = h >= 12 ? 'PM' : 'AM';
    const displayH = h % 12 === 0 ? 12 : h % 12;
    const displayM = m < 10 ? `0${m}` : m;
    return `${displayH}:${displayM} ${period}`;
  }

  function formatTime24(totalMins) {
    const h = Math.floor(totalMins / 60) % 24;
    const m = totalMins % 60;
    return `${h < 10 ? '0' + h : h}:${m < 10 ? '0' + m : m}`;
  }

  /**
   * Generates all chime timestamps (in minutes from midnight) for a reminder
   */
  function computeScheduleTimes(reminder) {
    const startMins = parseTimeToMinutes(reminder.startTime);
    let endMins = parseTimeToMinutes(reminder.endTime);
    const interval = Math.max(5, Number(reminder.intervalMinutes) || 60);

    // If end is smaller than start, assume overnight (though app encourages daytime window)
    if (endMins <= startMins) {
      endMins = 24 * 60;
    }

    const times = [];
    let current = startMins;
    while (current <= endMins) {
      times.push(current);
      current += interval;
    }
    return times;
  }

  /**
   * Analyzes today's status for a reminder
   */
  function getReminderDayStatus(reminder, now = new Date()) {
    const dayOfWeek = now.getDay(); // 0 is Sunday, 6 is Saturday
    const currentMins = now.getHours() * 60 + now.getMinutes();
    const isActiveToday = reminder.days.includes(dayOfWeek) && reminder.enabled && !reminder.pausedToday;

    const times = computeScheduleTimes(reminder);
    const pastTimes = times.filter(t => t < currentMins);
    const upcomingTimes = times.filter(t => t >= currentMins);
    const nextTime = upcomingTimes.length > 0 ? upcomingTimes[0] : null;

    let countdownMins = null;
    if (nextTime !== null && isActiveToday) {
      countdownMins = nextTime - currentMins;
    }

    return {
      isActiveToday,
      totalChimes: times.length,
      pastCount: pastTimes.length,
      remainingCount: upcomingTimes.length,
      nextTime,
      countdownMins,
      times
    };
  }

  // --- UI Renderers ---

  function renderStatusClock() {
    const now = new Date();
    let hours = now.getHours();
    let mins = now.getMinutes();
    const clockEl = document.getElementById('status-clock');
    if (clockEl) {
      clockEl.textContent = `${hours < 10 ? '0' + hours : hours}:${mins < 10 ? '0' + mins : mins}`;
    }

    // Dynamic greeting
    const greetingEl = document.getElementById('live-greeting');
    if (greetingEl) {
      const days = ['SUNDAY', 'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY'];
      greetingEl.textContent = `${days[now.getDay()]} • SCHEDULE`;
    }
  }

  /**
   * Renders the 24-hour bar visualizer at the top
   */
  function renderTimelineVisual() {
    const container = document.getElementById('timeline-hours-bar');
    if (!container) return;

    const now = new Date();
    const currentHour = now.getHours();
    const currentMins = currentHour * 60 + now.getMinutes();

    // Collect all active chimes across all enabled reminders for today
    const allChimeMinutes = new Set();
    let earliestStart = 24 * 60;
    let latestEnd = 0;

    reminders.forEach(r => {
      const status = getReminderDayStatus(r, now);
      if (status.isActiveToday) {
        status.times.forEach(t => allChimeMinutes.add(t));
        const s = parseTimeToMinutes(r.startTime);
        const e = parseTimeToMinutes(r.endTime);
        if (s < earliestStart) earliestStart = s;
        if (e > latestEnd) latestEnd = e;
      }
    });

    // Update count badge
    const badge = document.getElementById('rings-count-badge');
    if (badge) {
      badge.textContent = `${allChimeMinutes.size} Chimes`;
    }

    // Master next countdown
    const sortedChimes = Array.from(allChimeMinutes).sort((a, b) => a - b);
    const upcomingMaster = sortedChimes.filter(t => t >= currentMins);
    const nextMaster = upcomingMaster.length > 0 ? upcomingMaster[0] : null;

    const countdownLabel = document.getElementById('master-countdown');
    const islandText = document.getElementById('island-text');

    if (nextMaster !== null) {
      const diff = nextMaster - currentMins;
      const formatted = formatMinutesToTime(nextMaster);
      if (countdownLabel) {
        countdownLabel.textContent = diff === 0 ? `Chiming Now • ${formatted}` : `Next chime in ${diff}m (${formatted})`;
      }
      if (islandText) {
        islandText.textContent = `Next: ${formatted}`;
      }
    } else {
      if (countdownLabel) {
        countdownLabel.textContent = `Quiet night active • Safe sleep`;
      }
      if (islandText) {
        islandText.textContent = `Quiet Night`;
      }
    }

    container.innerHTML = '';
    for (let h = 0; h < 24; h++) {
      const slot = document.createElement('div');
      slot.className = 'timeline-hour-slot';
      slot.title = `${h}:00 - ${h + 1}:00`;

      // Check quiet hours (before 9 or after 21 by default if no reminders)
      const slotStartMins = h * 60;
      const slotEndMins = (h + 1) * 60;

      const isInsideAnyWindow = slotEndMins > earliestStart && slotStartMins < latestEnd;
      if (!isInsideAnyWindow && allChimeMinutes.size > 0) {
        slot.classList.add('quiet-hour');
      } else {
        slot.classList.add('active-window');
      }

      // Check if any chimes fall in this hour
      let hasChimeInHour = false;
      let hasPastChime = false;
      let isNextTarget = false;

      for (const cm of allChimeMinutes) {
        if (cm >= slotStartMins && cm < slotEndMins) {
          hasChimeInHour = true;
          if (cm < currentMins) hasPastChime = true;
          if (cm === nextMaster) isNextTarget = true;
        }
      }

      if (hasChimeInHour) {
        slot.classList.add('has-chime');
        if (hasPastChime && !isNextTarget) slot.classList.add('past');
        if (isNextTarget) slot.classList.add('next-target');
      }

      if (h === currentHour) {
        slot.classList.add('current-hour');
      }

      container.appendChild(slot);
    }
  }

  /**
   * Renders list of reminder cards
   */
  function renderReminders() {
    const listEl = document.getElementById('reminders-list');
    const emptyEl = document.getElementById('empty-state');
    if (!listEl) return;

    const now = new Date();
    let filtered = reminders;

    if (currentFilter === 'active') {
      filtered = reminders.filter(r => {
        const s = getReminderDayStatus(r, now);
        return s.isActiveToday;
      });
    }

    if (filtered.length === 0) {
      listEl.innerHTML = '';
      if (emptyEl) emptyEl.classList.remove('hidden');
      return;
    }

    if (emptyEl) emptyEl.classList.add('hidden');
    listEl.innerHTML = '';

    filtered.forEach(rem => {
      const status = getReminderDayStatus(rem, now);
      const card = document.createElement('div');
      card.className = `reminder-card ${rem.enabled ? '' : 'disabled'} ${rem.pausedToday ? 'paused' : ''}`;
      card.dataset.id = rem.id;

      // Frequency text
      const freqText = rem.intervalMinutes >= 60 
        ? `Every ${rem.intervalMinutes / 60}h` 
        : `Every ${rem.intervalMinutes}m`;

      // Window text
      const winText = `${formatMinutesToTime(parseTimeToMinutes(rem.startTime))} – ${formatMinutesToTime(parseTimeToMinutes(rem.endTime))}`;

      // Days badge
      let daysBadge = 'Daily';
      if (rem.days.length === 5 && !rem.days.includes(0) && !rem.days.includes(6)) {
        daysBadge = 'Weekdays';
      } else if (rem.days.length === 2 && rem.days.includes(0) && rem.days.includes(6)) {
        daysBadge = 'Weekends';
      } else if (rem.days.length < 7) {
        const dNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        daysBadge = rem.days.map(d => dNames[d]).join(', ');
      }

      // Next status string
      let nextStr = 'Disabled';
      if (rem.enabled) {
        if (rem.pausedToday) {
          nextStr = 'Paused for today';
        } else if (!status.isActiveToday) {
          nextStr = 'Inactive today';
        } else if (status.nextTime !== null) {
          const diff = status.countdownMins;
          nextStr = diff === 0 
            ? `Chiming Now` 
            : `Next in ${diff}m (${formatMinutesToTime(status.nextTime)})`;
        } else {
          nextStr = 'Completed for today (Safe sleep)';
        }
      }

      // Generate chime dots row
      const dotsHtml = status.times.slice(0, 16).map(t => {
        const currentM = now.getHours() * 60 + now.getMinutes();
        let cls = 'future';
        if (t < currentM) cls = 'past';
        if (t === status.nextTime) cls = 'next';
        return `<span class="chime-dot ${cls}" title="${formatMinutesToTime(t)}"></span>`;
      }).join('');

      card.innerHTML = `
        <div class="card-top-row">
          <div class="card-title-group">
            <div class="card-emoji-box">${rem.emoji || '💧'}</div>
            <div class="card-text-col">
              <h4 class="card-title">${rem.title}</h4>
              <div class="card-badges-row">
                <span class="meta-pill accent">${freqText}</span>
                <span class="meta-pill">${winText}</span>
                <span class="meta-pill">${daysBadge}</span>
                ${rem.pausedToday ? '<span class="meta-pill paused-pill">Paused Today</span>' : ''}
              </div>
            </div>
          </div>
          <label class="ios-switch">
            <input type="checkbox" class="reminder-toggle" ${rem.enabled ? 'checked' : ''}>
            <span class="switch-slider"></span>
          </label>
        </div>

        <div class="card-chime-dots-row">
          ${dotsHtml}
        </div>

        <div class="card-bottom-bar">
          <div class="next-run-tag">
            <span>⏰</span>
            <strong>${nextStr}</strong>
          </div>
          <div class="card-actions">
            <button class="action-pill-btn test-btn" title="Test chime audio">Test 🔔</button>
            <button class="action-pill-btn pause-btn" title="Pause or resume today">${rem.pausedToday ? 'Resume ▶️' : 'Pause ⏸️'}</button>
            <button class="action-pill-btn edit-btn" title="Edit reminder">Edit ✏️</button>
            <button class="action-pill-btn danger delete-btn" title="Delete">🗑️</button>
          </div>
        </div>
      `;

      // Event handlers for card buttons
      const toggleInput = card.querySelector('.reminder-toggle');
      toggleInput.addEventListener('change', (e) => {
        rem.enabled = e.target.checked;
        saveReminders();
        renderAll();
      });

      const testBtn = card.querySelector('.test-btn');
      testBtn.addEventListener('click', () => {
        triggerNotificationEvent(rem);
      });

      const pauseBtn = card.querySelector('.pause-btn');
      pauseBtn.addEventListener('click', () => {
        rem.pausedToday = !rem.pausedToday;
        saveReminders();
        renderAll();
      });

      const editBtn = card.querySelector('.edit-btn');
      editBtn.addEventListener('click', () => {
        openEditSheet(rem.id);
      });

      const deleteBtn = card.querySelector('.delete-btn');
      deleteBtn.addEventListener('click', () => {
        if (confirm(`Delete "${rem.title}"?`)) {
          reminders = reminders.filter(r => r.id !== rem.id);
          saveReminders();
          renderAll();
        }
      });

      listEl.appendChild(card);
    });
  }

  /**
   * Renders curated preset cards in bottom grid
   */
  function renderCuratedTemplates() {
    const grid = document.getElementById('templates-grid');
    if (!grid) return;

    grid.innerHTML = '';
    CURATED_TEMPLATES.forEach(tmpl => {
      const card = document.createElement('div');
      card.className = 'template-card';
      const freqLabel = tmpl.interval >= 60 ? `${tmpl.interval / 60}h` : `${tmpl.interval}m`;
      
      card.innerHTML = `
        <div class="template-top">
          <span class="template-emoji">${tmpl.emoji}</span>
          <span class="template-badge">${freqLabel}</span>
        </div>
        <div class="template-name">${tmpl.title}</div>
        <div class="template-sub">${tmpl.start} – ${tmpl.end} • ${tmpl.days}</div>
      `;

      card.addEventListener('click', () => {
        // Quick create reminder from preset
        const newRem = {
          id: 'rem-' + Date.now(),
          title: tmpl.title,
          emoji: tmpl.emoji,
          intervalMinutes: tmpl.interval,
          startTime: tmpl.start,
          endTime: tmpl.end,
          days: tmpl.days === 'weekdays' ? [1, 2, 3, 4, 5] : [0, 1, 2, 3, 4, 5, 6],
          sound: tmpl.sound,
          enabled: true,
          pausedToday: false,
          notes: ''
        };
        reminders.push(newRem);
        saveReminders();
        renderAll();
        triggerToastNotification(newRem.title, `Added to your hourly schedule (${tmpl.start} – ${tmpl.end}).`);
        playChime(newRem.sound);
      });

      grid.appendChild(card);
    });
  }

  // --- Dynamic Island & Toast Notifications ---

  function triggerNotificationEvent(reminder) {
    playChime(reminder.sound || 'zen_bell');

    // Expand Dynamic Island momentarily
    const island = document.getElementById('dynamic-island');
    if (island) {
      const expandedTitle = document.getElementById('island-expanded-title');
      const expandedTime = document.getElementById('island-expanded-time');
      if (expandedTitle) expandedTitle.textContent = `${reminder.emoji || ''} ${reminder.title}`;
      if (expandedTime) expandedTime.textContent = `Chiming every ${reminder.intervalMinutes}m until ${reminder.endTime}`;

      island.classList.add('expanded');
      setTimeout(() => {
        island.classList.remove('expanded');
      }, 4200);
    }

    // Trigger visual toast
    triggerToastNotification(
      `${reminder.emoji || '🔔'} ${reminder.title}`,
      reminder.notes || `Hourly reminder scheduled for ${formatMinutesToTime(parseTimeToMinutes(reminder.startTime))} – ${formatMinutesToTime(parseTimeToMinutes(reminder.endTime))}.`
    );

    // Trigger real system notification if permitted
    if ('Notification' in window && Notification.permission === 'granted') {
      try {
        new Notification(reminder.title, {
          body: reminder.notes || `Hourly reminder window is active (${reminder.startTime} - ${reminder.endTime}).`,
          icon: '/assets/icon.png',
          badge: '/assets/icon.png'
        });
      } catch (err) {
        console.log('Web notification trigger err:', err);
      }
    }
  }

  function triggerToastNotification(title, desc) {
    const toast = document.getElementById('notification-toast');
    const toastTitle = document.getElementById('toast-title');
    const toastDesc = document.getElementById('toast-desc');
    if (!toast) return;

    if (toastTitle) toastTitle.textContent = title;
    if (toastDesc) toastDesc.textContent = desc;

    toast.classList.add('show');
    clearTimeout(toast._timeout);
    toast._timeout = setTimeout(() => {
      toast.classList.remove('show');
    }, 4500);
  }

  // --- Modal Sheet: Add / Edit Reminder ---

  function openAddSheet() {
    editingReminderId = null;
    document.getElementById('sheet-title').textContent = 'New Hourly Reminder';
    document.getElementById('reminder-title-input').value = '';
    document.getElementById('selected-emoji-btn').textContent = '💧';
    document.getElementById('start-time-input').value = '09:00';
    document.getElementById('end-time-input').value = '21:00';

    // Reset frequency to 60m
    document.querySelectorAll('#freq-preset-selector .seg-btn').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.mins === '60');
    });
    document.getElementById('custom-mins-row').classList.add('hidden');
    document.getElementById('freq-summary-label').textContent = 'Every 1 Hour';

    // Reset days to daily
    document.querySelectorAll('#days-preset-selector .seg-btn').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.days === 'daily');
    });
    document.querySelectorAll('.day-bubble').forEach(b => b.classList.add('active'));
    document.getElementById('days-summary-label').textContent = 'Every Day';

    // Sound
    document.querySelectorAll('.sound-card').forEach(c => {
      c.classList.toggle('active', c.dataset.sound === 'zen_bell');
    });

    updateSheetSchedulePreview();
    document.getElementById('sheet-backdrop').classList.remove('hidden');
  }

  function openEditSheet(id) {
    const rem = reminders.find(r => r.id === id);
    if (!rem) return;

    editingReminderId = id;
    document.getElementById('sheet-title').textContent = 'Edit Hourly Reminder';
    document.getElementById('reminder-title-input').value = rem.title;
    document.getElementById('selected-emoji-btn').textContent = rem.emoji || '💧';
    document.getElementById('start-time-input').value = rem.startTime;
    document.getElementById('end-time-input').value = rem.endTime;

    // Frequency
    let foundPreset = false;
    document.querySelectorAll('#freq-preset-selector .seg-btn').forEach(btn => {
      if (btn.dataset.mins == rem.intervalMinutes) {
        btn.classList.add('active');
        foundPreset = true;
      } else {
        btn.classList.remove('active');
      }
    });

    if (!foundPreset) {
      document.querySelector('#freq-preset-selector [data-mins="custom"]').classList.add('active');
      document.getElementById('custom-mins-row').classList.remove('hidden');
      document.getElementById('custom-mins-input').value = rem.intervalMinutes;
    } else {
      document.getElementById('custom-mins-row').classList.add('hidden');
    }
    document.getElementById('freq-summary-label').textContent = rem.intervalMinutes >= 60 ? `Every ${rem.intervalMinutes / 60} Hour` : `Every ${rem.intervalMinutes}m`;

    // Days
    const activeDays = new Set(rem.days);
    document.querySelectorAll('.day-bubble').forEach(b => {
      b.classList.toggle('active', activeDays.has(Number(b.dataset.day)));
    });

    // Sound
    document.querySelectorAll('.sound-card').forEach(c => {
      c.classList.toggle('active', c.dataset.sound === (rem.sound || 'zen_bell'));
    });

    updateSheetSchedulePreview();
    document.getElementById('sheet-backdrop').classList.remove('hidden');
  }

  function closeSheet() {
    document.getElementById('sheet-backdrop').classList.add('hidden');
    editingReminderId = null;
  }

  function getSheetFormData() {
    const title = document.getElementById('reminder-title-input').value.trim() || 'Hourly Reminder';
    const emoji = document.getElementById('selected-emoji-btn').textContent || '💧';
    const startTime = document.getElementById('start-time-input').value || '09:00';
    const endTime = document.getElementById('end-time-input').value || '21:00';

    // Frequency
    let intervalMinutes = 60;
    const activeFreqBtn = document.querySelector('#freq-preset-selector .seg-btn.active');
    if (activeFreqBtn) {
      if (activeFreqBtn.dataset.mins === 'custom') {
        intervalMinutes = Math.max(5, Number(document.getElementById('custom-mins-input').value) || 60);
      } else {
        intervalMinutes = Number(activeFreqBtn.dataset.mins);
      }
    }

    // Days
    const days = [];
    document.querySelectorAll('.day-bubble.active').forEach(b => {
      days.push(Number(b.dataset.day));
    });

    // Sound
    const activeSound = document.querySelector('.sound-card.active');
    const sound = activeSound ? activeSound.dataset.sound : 'zen_bell';

    return {
      title,
      emoji,
      startTime,
      endTime,
      intervalMinutes,
      days: days.length > 0 ? days : [0, 1, 2, 3, 4, 5, 6],
      sound
    };
  }

  function updateSheetSchedulePreview() {
    const data = getSheetFormData();
    const times = computeScheduleTimes(data);

    const countEl = document.getElementById('preview-chimes-count');
    const container = document.getElementById('preview-chips-container');
    if (countEl) countEl.textContent = `${times.length} Chimes / Day`;

    if (container) {
      container.innerHTML = times.map(t => `<span class="preview-time-tag">${formatMinutesToTime(t)}</span>`).join('');
    }
  }

  function saveSheetData() {
    const data = getSheetFormData();

    if (editingReminderId) {
      const index = reminders.findIndex(r => r.id === editingReminderId);
      if (index !== -1) {
        reminders[index] = { ...reminders[index], ...data };
      }
    } else {
      const newRem = {
        id: 'rem-' + Date.now(),
        ...data,
        enabled: true,
        pausedToday: false,
        notes: ''
      };
      reminders.unshift(newRem);
    }

    saveReminders();
    closeSheet();
    renderAll();
    triggerToastNotification(data.title, 'Hourly reminder schedule saved!');
    playChime(data.sound);
  }

  // --- Master Clock Ticker ---
  function checkScheduleTriggers() {
    const now = new Date();
    const currentMinute = now.getHours() * 60 + now.getMinutes();

    renderStatusClock();
    renderTimelineVisual();

    // Avoid multiple triggers in the same minute
    if (currentMinute === lastCheckedMinute) return;
    lastCheckedMinute = currentMinute;

    reminders.forEach(r => {
      const status = getReminderDayStatus(r, now);
      if (status.isActiveToday && status.times.includes(currentMinute)) {
        triggerNotificationEvent(r);
      }
    });
  }

  function renderAll() {
    renderStatusClock();
    renderTimelineVisual();
    renderReminders();
    renderCuratedTemplates();
  }

  // --- Initializer & Event Listeners ---
  function init() {
    loadReminders();
    renderAll();

    // Start 1-second clock loop for real-time responsiveness
    setInterval(checkScheduleTriggers, 1000);

    // View Mode Toggle (iPhone Frame vs Fullscreen)
    document.querySelectorAll('#view-mode-toggle .seg-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        document.querySelectorAll('#view-mode-toggle .seg-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        if (btn.dataset.view === 'fullscreen') {
          document.body.classList.remove('desktop-mode');
          document.body.classList.add('fullscreen-mode');
        } else {
          document.body.classList.remove('fullscreen-mode');
          document.body.classList.add('desktop-mode');
        }
      });
    });

    // Unmute Audio button
    const toggleAudioBtn = document.getElementById('toggle-audio-btn');
    if (toggleAudioBtn) {
      toggleAudioBtn.addEventListener('click', () => {
        getAudioContext();
        playChime('zen_bell');
        toggleAudioBtn.textContent = '🔊 Audio Enabled';
      });
    }

    // Dynamic Island Tap -> expand and chime
    const dynamicIsland = document.getElementById('dynamic-island');
    if (dynamicIsland) {
      dynamicIsland.addEventListener('click', () => {
        getAudioContext();
        playChime('zen_bell');
        dynamicIsland.classList.toggle('expanded');
      });
    }

    // Notification Permission Request
    const permBtn = document.getElementById('btn-request-perm');
    if (permBtn) {
      permBtn.addEventListener('click', () => {
        getAudioContext();
        if ('Notification' in window) {
          Notification.requestPermission().then(permission => {
            const ind = document.getElementById('perm-indicator');
            if (ind) {
              ind.className = `perm-dot ${permission === 'granted' ? 'granted' : ''}`;
            }
            if (permission === 'granted') {
              triggerToastNotification('Notifications Enabled', 'HourPulse will chime at your scheduled hours.');
            }
          });
        } else {
          alert('Local web notifications supported. Tap "Add to Home Screen" on iPhone for standalone app experience.');
        }
      });
    }

    // Open Add Sheet
    const openAddBtn = document.getElementById('btn-open-add');
    const emptyAddBtn = document.getElementById('btn-empty-add');
    if (openAddBtn) openAddBtn.addEventListener('click', openAddSheet);
    if (emptyAddBtn) emptyAddBtn.addEventListener('click', openAddSheet);

    // Sheet Cancel / Save
    document.getElementById('btn-cancel-sheet').addEventListener('click', closeSheet);
    document.getElementById('btn-save-sheet').addEventListener('click', saveSheetData);
    document.getElementById('sheet-backdrop').addEventListener('click', (e) => {
      if (e.target.id === 'sheet-backdrop') closeSheet();
    });

    // Toast Dismiss
    const toastDismiss = document.getElementById('toast-dismiss');
    if (toastDismiss) {
      toastDismiss.addEventListener('click', () => {
        document.getElementById('notification-toast').classList.remove('show');
      });
    }

    // Reminders Filter Tabs
    document.querySelectorAll('#reminders-filter .seg-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        document.querySelectorAll('#reminders-filter .seg-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        currentFilter = btn.dataset.filter;
        renderReminders();
      });
    });

    // Emoji Picker Chips
    document.querySelectorAll('.emoji-chip').forEach(chip => {
      chip.addEventListener('click', () => {
        document.querySelectorAll('.emoji-chip').forEach(c => c.classList.remove('selected'));
        chip.classList.add('selected');
        document.getElementById('selected-emoji-btn').textContent = chip.dataset.emoji;
      });
    });

    // Frequency Preset Buttons in Sheet
    document.querySelectorAll('#freq-preset-selector .seg-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        document.querySelectorAll('#freq-preset-selector .seg-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        const isCustom = btn.dataset.mins === 'custom';
        document.getElementById('custom-mins-row').classList.toggle('hidden', !isCustom);
        document.getElementById('freq-summary-label').textContent = isCustom ? 'Custom' : (btn.dataset.mins >= 60 ? `Every ${btn.dataset.mins / 60} Hour` : `Every ${btn.dataset.mins}m`);
        updateSheetSchedulePreview();
      });
    });

    document.getElementById('custom-mins-input').addEventListener('input', updateSheetSchedulePreview);
    document.getElementById('start-time-input').addEventListener('input', updateSheetSchedulePreview);
    document.getElementById('end-time-input').addEventListener('input', updateSheetSchedulePreview);

    // Quick Window Chips in Sheet (e.g. 9 AM - 9 PM)
    document.querySelectorAll('.chip-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        document.getElementById('start-time-input').value = btn.dataset.start;
        document.getElementById('end-time-input').value = btn.dataset.end;
        updateSheetSchedulePreview();
      });
    });

    // Days Preset Buttons in Sheet
    document.querySelectorAll('#days-preset-selector .seg-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        document.querySelectorAll('#days-preset-selector .seg-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        const mode = btn.dataset.days;
        const bubbles = document.querySelectorAll('.day-bubble');

        if (mode === 'daily') {
          bubbles.forEach(b => b.classList.add('active'));
          document.getElementById('days-summary-label').textContent = 'Every Day';
        } else if (mode === 'weekdays') {
          bubbles.forEach(b => {
            const d = Number(b.dataset.day);
            b.classList.toggle('active', d >= 1 && d <= 5);
          });
          document.getElementById('days-summary-label').textContent = 'Weekdays Only';
        } else if (mode === 'weekends') {
          bubbles.forEach(b => {
            const d = Number(b.dataset.day);
            b.classList.toggle('active', d === 0 || d === 6);
          });
          document.getElementById('days-summary-label').textContent = 'Weekends Only';
        } else {
          document.getElementById('days-summary-label').textContent = 'Custom Days';
        }
        updateSheetSchedulePreview();
      });
    });

    // Day Bubbles Individual Click
    document.querySelectorAll('.day-bubble').forEach(b => {
      b.addEventListener('click', () => {
        b.classList.toggle('active');
        document.querySelectorAll('#days-preset-selector .seg-btn').forEach(s => s.classList.remove('active'));
        document.querySelector('#days-preset-selector [data-days="custom"]').classList.add('active');
        document.getElementById('days-summary-label').textContent = 'Custom Days';
        updateSheetSchedulePreview();
      });
    });

    // Sound Selection Cards
    document.querySelectorAll('.sound-card').forEach(card => {
      card.addEventListener('click', () => {
        document.querySelectorAll('.sound-card').forEach(c => c.classList.remove('active'));
        card.classList.add('active');
        playChime(card.dataset.sound);
      });
    });

    // Sound Preview Button
    document.getElementById('btn-preview-chime').addEventListener('click', () => {
      const activeSound = document.querySelector('.sound-card.active');
      playChime(activeSound ? activeSound.dataset.sound : 'zen_bell');
    });

    // Sideload / Install Guide Modal
    const guideBtn = document.getElementById('view-install-guide-btn');
    const guideModal = document.getElementById('guide-modal');
    const closeGuideBtn = document.getElementById('btn-close-guide');
    if (guideBtn && guideModal) {
      guideBtn.addEventListener('click', () => guideModal.classList.remove('hidden'));
    }
    if (closeGuideBtn && guideModal) {
      closeGuideBtn.addEventListener('click', () => guideModal.classList.add('hidden'));
      guideModal.addEventListener('click', (e) => {
        if (e.target.id === 'guide-modal') guideModal.classList.add('hidden');
      });
    }

    // Register Service Worker
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.register('/sw.js').catch(err => {
        console.log('SW registration error:', err);
      });
    }
  }

  // Launch when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
