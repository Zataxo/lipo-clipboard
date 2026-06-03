# Lipo (macOS Clipboard Manager)

A lightweight, modern clipboard manager for macOS built with Flutter. It runs as a menu bar app (tray icon + context menu) and stores clipboard history locally using Isar.

## Features

- Menu bar (tray) app experience
  - Left click toggles the window
  - Right click opens the tray context menu (Open/Hide, Clear History, Quit)
- Automatic clipboard capture (polls every 1 second)
  - Empty clipboard values are ignored
  - Duplicate texts are not duplicated; the existing entry is updated and moved to the top
- 512×512 fixed window with modern macOS-feeling UI
  - Search bar to filter clipboard history
  - Hover actions per row: Copy and Delete
  - Relative timestamps (e.g. “2m ago”)
  - Status bar with total count and “Clear All History”

## Project Structure

```
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

### Architecture Notes

- `DatabaseService` is the single entry point for Isar initialization and CRUD.
- `ClipboardProvider` is the reactive “app brain”: it initializes the database, loads history, runs the periodic clipboard polling loop, applies de-duplication rules, and notifies the UI.
- UI is intentionally small and focused to fit a fixed 512×512 dashboard. Hover interactions are implemented with `MouseRegion` + animated widgets for a native desktop feel.
