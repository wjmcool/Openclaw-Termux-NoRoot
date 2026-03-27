<p align="center">
  <h1 align="center">🤖 OpenClaw Termux No Root</h1>
  <p align="center">
    <strong>Control any Android phone via Telegram using Gemini AI — no root required.</strong><br>
    <sub>Powered by OpenClaw + Shizuku + Termux</sub>
  </p>
  <p align="center">
    <a href="#-quick-start">Quick Start</a> •
    <a href="#-features">Features</a> •
    <a href="#-commands">Commands</a> •
    <a href="#-how-it-works">How It Works</a> •
    <a href="#-credits">Credits</a>
  </p>
</p>

---

## ✨ What is OpenClaw Termux No Root?

**OpenClaw Termux NoRoot** turns your Android phone into an AI-powered remote control. Send natural language commands through **Telegram** — like *"check my battery"*, *"open YouTube"*, or *"turn off WiFi"* — and your phone executes them instantly.

It runs entirely on-device using **Termux** + **Shizuku** for privileged shell access, with **OpenClaw** as the AI gateway and **Google Gemini** as the brain.

**No root. No PC. No ADB cable. Just your phone.**

---

## 🚀 Features

- 💬 **Telegram Bot** — Send commands from anywhere in the world
- 🧠 **Gemini AI** — Understands natural language, not just keywords
- 📱 **30+ Device Commands** — WiFi, Bluetooth, calls, SMS, screenshots, volume, brightness & more
- 🤖 **Visual Agent** — AI-driven screen navigation for complex tasks (uses screenshots + UI parsing)
- 🔒 **No Root Required** — Uses Shizuku for ADB-level access without rooting
- ⚡ **1-Click Install** — Single script sets up everything

---

## 📋 Prerequisites

| Requirement | Details |
|---|---|
| **Android Phone** | Any phone running Android 11+ |
| **Shizuku** | [F-Droid](https://f-droid.org/packages/moe.shizuku.privileged.api/) or [Play Store](https://play.google.com/store/apps/details?id=moe.shizuku.privileged.api) |
| **Termux** | [F-Droid](https://f-droid.org/en/packages/com.termux/) ⚠️ *Do NOT use the Play Store version — it's outdated* |
| **Telegram Bot Token** | Get from [@BotFather](https://t.me/BotFather) on Telegram |
| **Gemini API Key** | Free from [Google AI Studio](https://aistudio.google.com/apikey) |

---

## 🏁 Quick Start

### Step 1 — Prepare Your Phone

1. **Enable Developer Options**
   - Go to `Settings → About Phone` and tap **"Build Number"** 7 times.

2. **Enable Wireless Debugging**
   - Go to `Settings → Developer Options → Wireless Debugging` and turn it **ON**.

3. **Install Termux** from [F-Droid](https://f-droid.org/en/packages/com.termux/).

4. **Install Shizuku** from [F-Droid](https://f-droid.org/packages/moe.shizuku.privileged.api/) or Play Store.

### Step 2 — Start Shizuku & Export Files

1. Open the **Shizuku** app → tap **"Pairing"** under Wireless Debugging.
2. In your phone's **Wireless Debugging settings**, tap **"Pair device with pairing code"** and enter the code into the Shizuku notification.
3. Tap **"Start"** in Shizuku until it says **"Shizuku is running"**.
4. In Shizuku, tap **"Use Shizuku in terminal apps"** → **"Export files"**.
5. Navigate to your **internal storage**, create a folder named exactly **`Shizuku`**, and tap **"Use this folder"**.

> [!IMPORTANT]
> The folder must be named exactly `Shizuku` (capital S) in your main internal storage. The installer looks for this specific path.

### Step 3 — Run the Installer

Open **Termux** and paste:

```bash
curl -sL https://raw.githubusercontent.com/jarvesusaram99/Openclaw-Termux-NoRoot/main/auto_setup.sh | bash
```


The installer will:
- ✅ Install all dependencies (Node.js, Git, ADB tools, etc.)
- ✅ Link Shizuku to Termux (`rish` & `shizuku` commands)
- ✅ Apply IPv4 DNS fix for Termux networking
- ✅ Install [OpenClaw](https://github.com/AidanPark/openclaw-android)
- ✅ Deploy phone control scripts & AI configuration

### Step 4 — Add Your Credentials

```bash
# Set up Telegram Bot
openclaw onboard

# Add your Gemini API Key
openclaw auth add google --key "YOUR_GEMINI_KEY_HERE"
```

### Step 5 — Launch! 🎉

```bash
openclaw gateway
```

Now open **Telegram**, find your bot, and try:
- `"What's my battery?"`
- `"Open Chrome"`
- `"Search YouTube for lofi beats"`
- `"Turn off WiFi"`
- `"Take a screenshot"`

---

## 📱 Commands

### ⚡ Smart Commands (Instant)

| Command | What it does |
|---|---|
| `battery` | Check battery level |
| `wifi on/off` | Toggle WiFi |
| `bluetooth on/off` | Toggle Bluetooth |
| `brightness 0-255` | Set screen brightness |
| `volume-up / volume-down` | Adjust volume |
| `mute` | Toggle mute |
| `lock` | Lock the screen |
| `screenshot` | Take a screenshot |
| `open-app <package>` | Launch any app |
| `kill-app <package>` | Force-stop an app |
| `list-apps` | List installed apps |
| `open-url <url>` | Open a URL in browser |
| `youtube-search <query>` | Search YouTube directly |
| `playstore-search <query>` | Search Play Store |
| `call <number>` | Make a phone call |
| `send-sms <number> <msg>` | Compose an SMS |
| `whatsapp-send <number> <msg>` | Send a WhatsApp message |
| `info` | Show device model & Android version |

### 🤖 Visual Agent (Complex Tasks)

For tasks that require navigating menus or interacting with app UIs:

```bash
bash ~/phone_agent.sh "Open Settings and enable Dark Mode"
bash ~/phone_agent.sh "Read my notifications"
bash ~/phone_agent.sh "Open WhatsApp and send a message to Mom"
```

The visual agent takes screenshots, reads UI elements with their coordinates, and uses Gemini to decide what to tap/type/swipe — fully autonomous, up to 15 steps.

---

## ⚙️ How It Works

```
┌─────────────┐     ┌──────────────┐     ┌──────────────┐     ┌─────────────┐
│  Telegram    │────▶│   OpenClaw   │────▶│  Gemini AI   │────▶│  Shizuku    │
│  (You)       │◀────│  (Gateway)   │◀────│  (Brain)     │◀────│  (rish)     │
└─────────────┘     └──────────────┘     └──────────────┘     └─────────────┘
                                                                     │
                                                                     ▼
                                                              ┌─────────────┐
                                                              │  Android    │
                                                              │  Phone      │
                                                              └─────────────┘
```

1. You send a message on **Telegram**
2. **OpenClaw** receives it and forwards to **Gemini AI**
3. Gemini understands the request and generates a shell command
4. The command runs via **Shizuku (rish)** — giving ADB-level access without root
5. Result is sent back to you on Telegram

---

## 📁 Project Structure

```
openclaw-termux-noroot/
├── auto_setup.sh    # 1-click universal installer (sets up everything)
├── LICENSE
└── README.md
```

---

## 🔧 Troubleshooting

| Problem | Solution |
|---|---|
| `rish: command not found` | Re-run `bash ~/storage/shared/Shizuku/copy.sh` |
| Shizuku not responding | Open Shizuku app → ensure it says "Running" → run `shizuku` in Termux |
| Network errors in Termux | Run `export NODE_OPTIONS=--dns-result-order=ipv4first` |
| `rish_shizuku.dex` not found | In Shizuku app → "Use in terminal apps" → "Export files" → save to `Shizuku` folder |
| API key errors | Run `openclaw auth add google --key "YOUR_KEY"` |

---

## 🙏 Credits

- **[OpenClaw Android](https://github.com/AidanPark/openclaw-android)** by [AidanPark](https://github.com/AidanPark) — The AI gateway framework that makes this possible. This project uses OpenClaw to bridge Telegram with Gemini AI on Android.
- **[Shizuku](https://github.com/RikkaApps/Shizuku)** by RikkaApps — ADB-level access without root.
- **[Termux](https://github.com/termux/termux-app)** — Linux terminal emulator for Android.
- **[Google Gemini](https://ai.google.dev/)** — The AI brain powering natural language understanding.

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  <strong>Made with ❤️ for Android automation</strong><br>
  <sub>No root. No PC. Just vibes.</sub>
</p>
