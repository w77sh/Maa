# Development Guide

## Prerequisites

- macOS 14.0 (Sonoma) or newer
- Xcode 15.0 or newer (Swift 5.9+)

## Building and Installing Locally

### Method 1: Using the Installation Script (Recommended)

```bash
cd Maa
./scripts/install-local-app.sh
```

This script automatically builds the app and installs it to `/Applications/`.

### Method 2: Manual Build with Xcode

1. Clone the repository:
   ```bash
   git clone https://github.com/w77sh/Maa.git
   cd Maa
   ```

2. Open the project in Xcode:
   ```bash
   open "Drink Reminder.xcodeproj"
   ```

3. Build and run:
   - Select the "Drink Reminder" scheme
   - Press `Cmd + R` to build and run
   - The app will launch automatically

### Method 3: Command Line Build

```bash
xcodebuild -scheme "Drink Reminder" -configuration Release build
```

## Running Tests

```bash
xcodebuild test -scheme "Drink Reminder"
```

Or in Xcode: `Cmd + U`

## Project Structure

```
Drink Reminder/
├── App/                 # Application entry point
├── MenuBar/             # Menu bar UI components
├── Settings/            # Settings view and logic
├── UI/                  # General UI components
├── Utils/               # Utility functions
├── Model/               # Data models
├── Notification/        # Notification handling
└── Localization/        # Language files (en.lproj, ar.lproj)

Drink ReminderTests/
├── SettingsStoreTests.swift
└── IconGenerationTests.swift
```

## Adding Translations

To add support for a new language:

1. Create a new `.lproj` folder with the ISO language code:
   ```bash
   mkdir "Drink Reminder/[language].lproj"
   ```

2. Copy the base localization file:
   ```bash
   cp "Drink Reminder/en.lproj/Localizable.strings" "Drink Reminder/[language].lproj/Localizable.strings"
   ```

3. Translate all values while keeping the keys intact

4. Update `AppLanguage` enum in `Localizer.swift` to include the new language

5. Submit a Pull Request!

## Code Style

- Follow Swift conventions and naming guidelines
- Use SwiftUI for all UI components
- Keep Views focused and under 200 lines
- Extract complex logic into separate utility files
- Always add proper error handling

## Debugging

### Enable Debug Logging

Set environment variables in Xcode scheme:

- `DEBUG_REMINDERS=1` - Enable reminder debug output
- `DEBUG_NOTIFICATIONS=1` - Enable notification debug output

### Common Issues

**App doesn't appear in menu bar:**
- Ensure notifications are enabled in System Settings
- Check System Preferences > Notifications & Focus

**Reminders not triggering:**
- Verify app has notification permissions
- Check that start/end times are configured correctly

## Building for Release

```bash
xcodebuild -scheme "Drink Reminder" -configuration Release archive
```

The generated `.app` bundle is ready for distribution.

## Contributing

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Make your changes
3. Run tests: `xcodebuild test -scheme "Drink Reminder"`
4. Commit: `git commit -am "feat: description"`
5. Push and create a Pull Request

## License

This project is licensed under the MIT License.
