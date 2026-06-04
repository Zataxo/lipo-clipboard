# Lipo (macOS Clipboard Manager)

A lightweight, modern clipboard manager for macOS built with Flutter. It runs as a menu bar app (tray icon + context menu) and stores clipboard history locally using Isar.

## Showcase

Here is a quick look at the user experience and configuration dialogs:

### 1. Set Shortcut Dialog

Configure your preferred global hotkey combination to summon the clipboard manager instantly from anywhere in macOS.

![Set Shortcut Dialog](assets/images/shortcut_dialog.png)

### 2. Main Application Interface

A sleek, focused view of your clipboard history complete with instant search, quick actions, and relative metadata.

![Main App Dashboard](assets/images/main_app.png)

> 💡 **System Tray Lifecycle:** After initial configuration, the main window will slide away, and the application will reside quietly in your **system tray (menu bar)**. You can summon it at any time using your designated shortcut or by clicking the menu bar icon.

---

## Features

- **Menu bar (tray) app experience**
  - Left click toggles the window
  - Right click opens the tray context menu (Open/Hide, Change Shortcut, Clear History, Quit)
  - **Dynamic Configuration:** Quickly set or reconfigure a new global shortcut directly from the system tray menu at any time.
- **Customizable Global Hotkeys**
  - Register a system-wide keyboard shortcut to instantly show/hide the clipboard panel from any screen or application.
- **Automatic clipboard capture** (polls every 1 second)
  - Empty clipboard values are ignored
  - Duplicate texts are not duplicated; the existing entry is updated and moved to the top
- **512×512 fixed window with modern macOS-feeling UI**
  - Search bar to filter clipboard history
  - Hover actions per row: Copy and Delete
  - Relative timestamps (e.g. “2m ago”)
  - Status bar with total count and “Clear All History”

## Project Structure

```text
lib/
  db/
    clipboard_item.dart
    database_service.dart
  presentation/
    provider/
      clipboard_provider.dart
    ui/
      app.dart
      dashboard_page.dart
  main.dart
```
