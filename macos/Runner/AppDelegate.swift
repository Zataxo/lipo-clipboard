import Cocoa
import FlutterMacOS
import Carbon

@main
class AppDelegate: FlutterAppDelegate {
  static weak var mainWindow: NSWindow?
  private let hotKeyManager = HotKeyManager.shared

  override func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)
    hotKeyManager.onHotKeyPressed = {
      AppDelegate.toggleMainWindow()
    }
    hotKeyManager.registerFromDefaultsIfPresent()
    super.applicationDidFinishLaunching(notification)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  static func toggleMainWindow() {
    guard let window = mainWindow else { return }
    if window.isVisible {
      window.orderOut(nil)
    } else {
      window.makeKeyAndOrderFront(nil)
      NSApp.activate(ignoringOtherApps: true)
    }
  }
}

final class HotKeyManager {
  static let shared = HotKeyManager()

  private let defaults = UserDefaults.standard
  private let defaultsKeyCodeKey = "lipo_hotkey_keyCode"
  private let defaultsModifiersKey = "lipo_hotkey_modifiers"

  private let signature: OSType = 0x4C49504F // "LIPO"
  private let hotKeyId: UInt32 = 1

  private var handlerRef: EventHandlerRef?
  private var hotKeyRef: EventHotKeyRef?

  var onHotKeyPressed: (() -> Void)?

  func registerFromDefaultsIfPresent() {
    guard let keyCodeNumber = defaults.object(forKey: defaultsKeyCodeKey) as? NSNumber,
          let modifiersNumber = defaults.object(forKey: defaultsModifiersKey) as? NSNumber else {
      return
    }
    _ = register(keyCode: UInt32(truncating: keyCodeNumber), modifiers: UInt32(truncating: modifiersNumber))
  }

  func currentHotKey() -> (keyCode: UInt32, modifiers: UInt32)? {
    guard let keyCodeNumber = defaults.object(forKey: defaultsKeyCodeKey) as? NSNumber,
          let modifiersNumber = defaults.object(forKey: defaultsModifiersKey) as? NSNumber else {
      return nil
    }
    return (UInt32(truncating: keyCodeNumber), UInt32(truncating: modifiersNumber))
  }

  func updateHotKey(keyCode: UInt32, modifiers: UInt32) -> Bool {
    let previous = currentHotKey()
    unregister()
    installHandlerIfNeeded()

    let ok = registerCore(keyCode: keyCode, modifiers: modifiers)
    if ok {
      defaults.set(NSNumber(value: keyCode), forKey: defaultsKeyCodeKey)
      defaults.set(NSNumber(value: modifiers), forKey: defaultsModifiersKey)
      defaults.synchronize()
      return true
    }

    if let previous = previous {
      _ = registerCore(keyCode: previous.keyCode, modifiers: previous.modifiers)
    }
    return false
  }

  func clear() {
    unregister()
    defaults.removeObject(forKey: defaultsKeyCodeKey)
    defaults.removeObject(forKey: defaultsModifiersKey)
    defaults.synchronize()
  }

  func register(keyCode: UInt32, modifiers: UInt32) -> Bool {
    unregister()
    installHandlerIfNeeded()
    return registerCore(keyCode: keyCode, modifiers: modifiers)
  }

  private func unregister() {
    if let ref = hotKeyRef {
      UnregisterEventHotKey(ref)
      hotKeyRef = nil
    }
  }

  private func installHandlerIfNeeded() {
    if handlerRef != nil { return }

    let eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

    let status = InstallEventHandler(
      GetApplicationEventTarget(),
      { (_, event, userData) -> OSStatus in
        guard let event = event else { return OSStatus(eventNotHandledErr) }
        guard let userData = userData else { return OSStatus(eventNotHandledErr) }
        let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()

        var hkID = EventHotKeyID()
        let getStatus = GetEventParameter(
          event,
          EventParamName(kEventParamDirectObject),
          EventParamType(typeEventHotKeyID),
          nil,
          MemoryLayout<EventHotKeyID>.size,
          nil,
          &hkID
        )
        if getStatus == noErr, hkID.signature == manager.signature, hkID.id == manager.hotKeyId {
          DispatchQueue.main.async {
            manager.onHotKeyPressed?()
          }
          return noErr
        }

        return OSStatus(eventNotHandledErr)
      },
      1,
      [eventSpec],
      UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
      &handlerRef
    )

    if status != noErr {
      handlerRef = nil
    }
  }

  private func registerCore(keyCode: UInt32, modifiers: UInt32) -> Bool {
    let hotKeyID = EventHotKeyID(signature: signature, id: hotKeyId)
    let status = RegisterEventHotKey(
      keyCode,
      modifiers,
      hotKeyID,
      GetApplicationEventTarget(),
      0,
      &hotKeyRef
    )
    if status != noErr {
      hotKeyRef = nil
      return false
    }
    return true
  }
}
