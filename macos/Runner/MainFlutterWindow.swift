import Cocoa
import FlutterMacOS
import Carbon

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    
    self.setFrame(NSRect(x: 0, y: 0, width: 512, height: 512), display: true)
    
    self.minSize = NSSize(width: 512, height: 512) 
    self.maxSize = NSSize(width: 512, height: 512) 
    
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
          self.makeKeyAndOrderFront(nil)
          NSApp.activate(ignoringOtherApps: true)
          result(nil)
        case "hide":
          self.orderOut(nil)
          result(nil)
        case "toggle":
          if self.isVisible {
            self.orderOut(nil)
          } else {
            self.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
          }
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

    super.awakeFromNib()

    AppDelegate.mainWindow = self

    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      if HotKeyManager.shared.currentHotKey() != nil {
        self.orderOut(nil)
      } else {
        self.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
      }
    }
  }
}
