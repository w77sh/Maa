# Maa'

Maa' is a lightweight macOS menu bar app that reminds you to drink water during the hours you choose.

It lives in the menu bar, sends reminders at a fixed interval, and lets you quickly snooze, pause, or log a drink.

## Screenshots

<!-- Add your screenshots here. For example: -->
<!-- ![Menu Bar App](path/to/screenshot1.png) -->
<!-- ![Settings Window](path/to/screenshot2.png) -->
## Download and install

1. Download the latest `Maa'.app.zip` from GitHub Releases.
2. Unzip the file.
3. Drag `Maa'.app` into your `Applications` folder.
4. Open the app.

After the app launches, you should see a water bottle icon in the macOS menu bar.

## If macOS says the app cannot be opened

This build is currently **not code signed / notarized**, so macOS may block it the first time you try to open it.

Try these options in order:

### Option 1: Open from the context menu

1. Open `Applications`.
2. Find `Maa'.app`.
3. Right-click the app and choose `Open`.
4. Click `Open` again in the confirmation dialog.

This is usually the simplest fix.

### Option 2: Allow it in Privacy & Security

If you already tried to open it and macOS blocked it:

1. Open `System Settings`.
2. Go to `Privacy & Security`.
3. Scroll down to the security section.
4. Look for a message saying `Maa'` was blocked.
5. Click `Open Anyway`.
6. Confirm by clicking `Open`.

### Option 3: Remove the quarantine flag in Terminal

Use this only if you trust the app and the two options above still do not work.

```bash
xattr -dr com.apple.quarantine /Applications/Drink\ Reminder.app
```

Then try opening the app again.

## First launch

On first launch, the app may ask for permission to send notifications. Allow notifications if you want reminder alerts from macOS.

The app does not open like a normal window-based app. It runs in the menu bar.

## How to use

Click the menu bar icon to open the app menu.

From there you can:

- `Drink now`: mark a drink and restart the reminder schedule
- `Snooze 30 minutes`: delay the next reminder by 30 minutes
- `Pause today`: stop reminders for the rest of the day
- `Resume reminders`: start reminders again after pausing
- `Settings`: change your schedule and notification behavior
- `Quit`: close the app

## Settings

In `Settings`, you can configure:

- reminder interval
- start time
- end time
- whether system notifications are enabled

Default settings:

- reminder every `60 minutes`
- reminder window from `9:00` to `20:00`
- notifications enabled

## Notes

- `Pause today` resets automatically the next day.
- If notifications are disabled in macOS, the menu will show a shortcut to open notification settings.
- The app is designed to stay out of the way and run quietly from the menu bar.
