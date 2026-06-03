import Cocoa
import FlutterMacOS

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
    super.awakeFromNib()
    
    DispatchQueue.main.async { [weak self] in
      self?.orderOut(nil)
    }
  }
}
