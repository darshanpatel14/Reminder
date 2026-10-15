# HourPulse 🔔 — Daily Hourly Reminders for iPhone (with Quiet-Night Protection)

[![Build Shareable iOS IPA](https://github.com/OWNER/REPO/actions/workflows/build-ipa.yml/badge.svg)](https://github.com/OWNER/REPO/actions/workflows/build-ipa.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

An open-source daily hourly reminder iOS app built to solve the #1 flaw in Apple's built-in Reminders: **repeating reminders chime 24/7 continuously throughout the night**.

**HourPulse** schedules periodic hourly chimes **strictly inside your chosen daytime window** (e.g. 9:00 AM – 9:00 PM), guaranteeing zero disturbance while you sleep.

---

## 🚀 How GitHub Actions Builds the Shareable `.ipa`

This repository includes an automated GitHub Actions CI/CD workflow:
[`.github/workflows/build-ipa.yml`](.github/workflows/build-ipa.yml)

Whenever you push to GitHub or trigger the workflow:
1. GitHub spins up a **macOS Apple Silicon runner** (`macos-14`) with the full **Xcode** and **iPhoneOS SDK**.
2. It compiles the native Swift / SwiftUI codebase into a real **ARM64 Mach-O binary**.
3. It packages the application into a clean `HourPulse.ipa`.
4. It automatically publishes the `.ipa` to **GitHub Releases** and **Workflow Artifacts** so anyone can download it with a single click.

---

## 📲 How to Install & Share with Friends (No Errors)

### Method 1: Sideload the Compiled `.ipa` via Sideloadly (Native App)
1. Download `HourPulse.ipa` from the **Releases** tab on GitHub.
2. Open **[Sideloadly](https://sideloadly.io)** (free for Mac & Windows).
3. Connect your iPhone via USB.
4. Drag `HourPulse.ipa` into Sideloadly, enter your Apple ID, and click **Start**.
5. On your iPhone: Go to **Settings > General > VPN & Device Management** and tap **Trust**.

### Method 2: Instant Web App (No Computer Needed — 10 Seconds)
1. Deploy the `HourPulse-Web/` folder to [Vercel](https://vercel.com) or GitHub Pages for free.
2. Send the link to your friend.
3. Your friend opens the link in **Safari on iPhone** and taps **Share > Add to Home Screen**.

---

## 🛠️ Repository Architecture

```
Reminder/
├── .github/
│   └── workflows/
│       └── build-ipa.yml         # GitHub Actions automated IPA builder
├── HourPulse-iOS/                # Native Swift / SwiftUI iOS application
│   ├── HourPulse.xcodeproj      # Xcode project with shared schemes
│   └── HourPulse/
│       ├── App/                  # App entry point
│       ├── Models/               # Data model & daytime window calculations
│       ├── Services/             # UNUserNotificationCenter calendar triggers
│       ├── Views/                # SwiftUI UI views & components
│       └── Resources/            # Info.plist & Assets
├── HourPulse-Web/                # Standalone Web Companion & PWA
│   ├── index.html                # Responsive iOS 18 shell UI
│   ├── app.css                   # Dark titanium HIG design system
│   ├── app.js                    # Web Audio synthesis & reminder engine
│   └── manifest.json             # iOS standalone PWA config
├── LICENSE                       # MIT License
└── README.md
```

---

## 🐙 Push to GitHub

To publish this open-source project and trigger the automatic IPA build:

```bash
git init
git add .
git commit -m "feat: initial commit of HourPulse"
git branch -M main
git remote add origin https://github.com/<your-username>/hourpulse.git
git push -u origin main
```
