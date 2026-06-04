import Cocoa
import FlutterMacOS
import Carbon

class MainFlutterWindow: NSPanel {
  private static let overlaySize = NSSize(width: 560, height: 560)

  private var overlayChannel: FlutterMethodChannel?
  private var globalMouseMonitor: Any?
  private var localKeyMonitor: Any?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    
    self.setFrame(
      NSRect(x: 0, y: 0, width: Self.overlaySize.width, height: Self.overlaySize.height),
      display: true
    )
    
    self.minSize = Self.overlaySize
    self.maxSize = Self.overlaySize

    configureOverlayPanel()
    
    RegisterGeneratedPlugins(registry: flutterViewController)
    
    let channel = FlutterMethodChannel(
      name: "lipo/window",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
        guard let self = self else {
          result(FlutterError(code: "unavailable", message: "Window deallocated", details: nil))
          return
        }
        
        switch call.method {
        case "show":
          self.showOverlay()
          result(nil)
        case "hide":
          self.hideOverlay()
          result(nil)
        case "toggle":
          self.toggleOverlay()
          result(nil)
        case "isVisible":
          result(self.isVisible)
        default:
          result(FlutterMethodNotImplemented)
        }
      }

    let hotKeyChannel = FlutterMethodChannel(
      name: "lipo/hotkey",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    hotKeyChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "get":
        if let current = HotKeyManager.shared.currentHotKey() {
          result([
            "keyCode": Int(current.keyCode),
            "modifiers": Int(current.modifiers),
          ])
        } else {
          result(nil)
        }
      case "set":
        guard let args = call.arguments as? [String: Any],
              let keyCode = args["keyCode"] as? Int else {
          result(FlutterError(code: "bad_args", message: "Missing keyCode", details: nil))
          return
        }

        let cmd = (args["cmd"] as? Bool) ?? false
        let alt = (args["alt"] as? Bool) ?? false
        let ctrl = (args["ctrl"] as? Bool) ?? false
        let shift = (args["shift"] as? Bool) ?? false

        var modifiers: UInt32 = 0
        if cmd { modifiers |= UInt32(cmdKey) }
        if alt { modifiers |= UInt32(optionKey) }
        if ctrl { modifiers |= UInt32(controlKey) }
        if shift { modifiers |= UInt32(shiftKey) }

        let ok = HotKeyManager.shared.updateHotKey(keyCode: UInt32(keyCode), modifiers: modifiers)
        result(ok)
      case "clear":
        HotKeyManager.shared.clear()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    overlayChannel = FlutterMethodChannel(
      name: "lipo/overlay",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )

    super.awakeFromNib()

    AppDelegate.mainWindow = self
    delegate = self

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(onResignKey),
      name: NSWindow.didResignKeyNotification,
      object: self
    )

    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      if HotKeyManager.shared.currentHotKey() != nil {
        self.hideOverlay()
      } else {
        self.showOverlay()
      }
    }
  }

  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { true }

  override func makeKeyAndOrderFront(_ sender: Any?) {
    repositionToMouseScreenCenter()
    super.makeKeyAndOrderFront(sender)
  }

  func toggleOverlay() {
    if isVisible {
      hideOverlay()
    } else {
      showOverlay()
    }
  }

  func showOverlay() {
    repositionToMouseScreenCenter()
    alphaValue = 1.0
    orderFrontRegardless()
    NSApp.activate(ignoringOtherApps: true)
    makeKeyAndOrderFront(nil)
    overlayChannel?.invokeMethod("didShow", arguments: nil)
    installOverlayEventMonitorsIfNeeded()
  }

  func hideOverlay() {
    orderOut(nil)
  }

  @objc private func onResignKey() {
    hideOverlay()
  }

  private func configureOverlayPanel() {
    styleMask = [
      .titled,
      .fullSizeContentView,
      .nonactivatingPanel,
      .hudWindow,
    ]

    // level = .statusWindow
    collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]

    isReleasedWhenClosed = false
    hidesOnDeactivate = false
    becomesKeyOnlyIfNeeded = false

    titleVisibility = .hidden
    titlebarAppearsTransparent = true
    standardWindowButton(.closeButton)?.isHidden = true
    standardWindowButton(.miniaturizeButton)?.isHidden = true
    standardWindowButton(.zoomButton)?.isHidden = true

    isOpaque = false
    backgroundColor = .clear
    hasShadow = true
    isMovableByWindowBackground = true
  }

  private func activeScreenForMouse() -> NSScreen? {
    let mousePoint = NSEvent.mouseLocation
    return NSScreen.screens.first(where: { NSMouseInRect(mousePoint, $0.frame, false) })
  }

  private func repositionToMouseScreenCenter() {
    let targetScreen = activeScreenForMouse() ?? NSScreen.main
    guard let screen = targetScreen else { return }

    let visibleFrame = screen.visibleFrame
    let size = Self.overlaySize
    let x = visibleFrame.origin.x + (visibleFrame.size.width - size.width) / 2.0
    let y = visibleFrame.origin.y + (visibleFrame.size.height - size.height) / 2.0
    setFrame(NSRect(x: x, y: y, width: size.width, height: size.height), display: false)
  }

  private func installOverlayEventMonitorsIfNeeded() {
    if globalMouseMonitor == nil {
      globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
        guard let self = self else { return }
        if !self.isVisible { return }
        let mouse = NSEvent.mouseLocation
        if !self.frame.contains(mouse) {
          DispatchQueue.main.async {
            self.hideOverlay()
          }
        }
      }
    }

    if localKeyMonitor == nil {
      localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
        guard let self = self else { return event }
        if !self.isVisible { return event }
        if event.keyCode == 53 {
          self.hideOverlay()
          return nil
        }
        return event
      }
    }
  }
}

extension MainFlutterWindow: NSWindowDelegate {
  func windowDidResignKey(_ notification: Notification) {
    hideOverlay()
  }
}
