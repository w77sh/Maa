<p align="center">
  <img src="https://raw.githubusercontent.com/w77sh/Maa/main/Drink%20Reminder/Assets.xcassets/AppIcon.appiconset/256.png" width="96" height="96" alt="Maa' App Icon" />
</p>

<h1 align="center">Maa' (ماء)</h1>

<p align="center">
  <b>A lightweight, native, and exceptionally battery-friendly macOS status bar companion designed to keep you hydrated.</b>
</p>

<p align="center">
  <a href="https://developer.apple.com/swift/">
    <img src="https://img.shields.io/badge/Swift-5.9+-FA7343?style=flat-square&logo=Swift" alt="Swift 5.9+" />
  </a>
  <a href="https://developer.apple.com/macos/">
    <img src="https://img.shields.io/badge/macOS-14.0+-000000?style=flat-square&logo=Apple" alt="macOS 14.0+" />
  </a>
  <a href="https://brew.sh/">
    <img src="https://img.shields.io/badge/Homebrew-Cask-FFDE59?style=flat-square&logo=Homebrew&logoColor=black" alt="Homebrew Cask" />
  </a>
  <a href="https://sparkle-project.org/">
    <img src="https://img.shields.io/badge/Updates-Sparkle-0071E3?style=flat-square" alt="Sparkle Updater" />
  </a>
  <a href="https://opensource.org/licenses/MIT">
    <img src="https://img.shields.io/badge/License-MIT-34C759?style=flat-square" alt="License: MIT" />
  </a>
</p>

---

Maa' (Arabic for *Water*) is a beautifully designed macOS menu bar utility that reminds you to drink water at intervals you define. Built entirely with **SwiftUI** and native AppKit integrations, it feels like a first-party utility built by Apple. It operates with a strict focus on system efficiency, native aesthetics, and user productivity.

## 🛠 Features & Architecture

### ⚡️ Zero-Polling Engine (App Nap Friendly)
Most hydration utilities run background polling loops or heavy `Timer` loops that wake up the CPU every minute to calculate trigger times. This drains notebook batteries and prevents the OS from entering deep sleep states. 

Maa' is built around a **reactive scheduling engine**:
* When you log a drink, the app pre-calculates the exact timestamp of your next notification.
* It registers a native local notification trigger via `UNUserNotificationCenter` and immediately goes to sleep.
* The application consumes **0.0% CPU** in the background, fully respecting macOS **App Nap**. The OS wakes the app up only when you interact with it or receive a notification.

### 🎨 Premium status Bar UI
* **Fluid Cup Animation**: A custom SwiftUI fluid wave shader that dynamically rises and moves to visualize your real-time consumption progress.
* **Monochrome or Color Icon**: A quick toggle in settings lets you choose between a vibrant colored status bar drop icon and a clean, system-matching monochrome icon.
* **Status Badges**: Hitting your daily water target triggers a beautiful in-menu celebration card and applies a subtle green checkmark badge directly to the status bar icon, providing a silent, rewarding confirmation of your goal.
* **Refined Hover States**: Premium transitions and micro-interaction states on all status bar popover buttons.

### ⚙️ Native Settings & Time Picker
* Follows Apple's Human Interface Guidelines (HIG) with tabbed settings (`General`, `Goal`, `Schedule`).
* Integrates compact macOS native `DatePicker` controls instead of manual, error-prone text input fields.

### 🌐 Easy Open-Source Localization
* Dynamic bilingual localization support (English & Arabic) configured using decoupled `.lproj` resource folders to make it extremely easy for community developers to contribute new language packs.

---

## 📸 Screenshots

To help users understand the app instantly, here are key screenshots of the user interface. 

> [!TIP]
> **To the Repository Owner**: Please take screenshots of your app running locally, place them in a folder (e.g. `docs/screenshots/`), and link them below replacing the placeholder blocks.

#### 1. Menu Bar Popover & Wave Animation
> **How to capture**: Open the Maa' dropdown from the status bar, log a drink to see the fluid animation inside the cup, and take a screenshot of the popup. Save as `docs/screenshots/menu-bar-popover.png`.
```markdown
<!-- Replace this with: ![Maa' Menu Bar View](docs/screenshots/menu-bar-popover.png) -->
```

#### 2. Native Tabbed Settings
> **How to capture**: Click "Settings" in the app, click the "Schedule" or "Goal" tab to display the native macOS compact time pickers and monochrome toggle. Save as `docs/screenshots/settings-panel.png`.
```markdown
<!-- Replace this with: ![Maa' Settings Window](docs/screenshots/settings-panel.png) -->
```

#### 3. Daily Goal Reached & Status Badge
> **How to capture**: Add enough water intake to hit your daily goal. Capture the congrats animation card inside the menu popover, or the green checkmark badge on the status bar icon. Save as `docs/screenshots/goal-reached.png`.
```markdown
<!-- Replace this with: ![Maa' Daily Goal Reached](docs/screenshots/goal-reached.png) -->
```

---

## 📥 Installation

### Method 1: Homebrew Cask (Recommended)
You can install Maa' directly via Homebrew from the official custom tap:

```bash
# Add the tap
brew tap w77sh/tap

# Install Maa'
brew install --cask maa
```

### Method 2: Direct DMG Download
1. Navigate to the [Releases](https://github.com/w77sh/Maa/releases) page.
2. Download the latest `Maa-[Version]-[Build]-macOS.dmg` archive.
3. Open the DMG and drag **Maa'** to your `Applications` directory.

> [!NOTE]  
> Because Maa' is distributed as a self-signed binary, macOS Gatekeeper may block launch on first run. To allow the app:
> * Right-click `Maa'.app` in your Applications folder and select **Open**.
> * Alternatively, strip the quarantine flag via terminal:
>   ```bash
>   xattr -dr com.apple.quarantine /Applications/Maa\'.app
>   ```

---

## 💻 Local Development

### Prerequisites
* macOS 14.0 (Sonoma) or newer.
* Xcode 15.0 or newer (Swift 5.9+).

### Building & Running
Clone the repository:
```bash
git clone https://github.com/w77sh/Maa.git
cd Maa
```

To compile and install the application locally into your `/Applications` directory, run the helper script:
```bash
./scripts/install-local-app.sh
```

### Adding New Translations
Maa' makes it straightforward to add new languages. Translations are organized into separate `.lproj` folders under `Drink Reminder/`:
1. Create a new directory named after the ISO language code (e.g. `fr.lproj` for French) inside `Drink Reminder/`.
2. Add a `Localizable.strings` file inside it.
3. Copy the keys from `Drink Reminder/en.lproj/Localizable.strings` and translate the values.
4. Open a Pull Request!

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
