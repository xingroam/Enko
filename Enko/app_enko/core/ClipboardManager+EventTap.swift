import AppKit
import ApplicationServices

extension ClipboardManager {
  func start() {
    setupAppActiveObserverIfNeeded()
    setupWorkspaceSecurityObserversIfNeeded()
    guard eventTap == nil else { return }
    guard AXIsProcessTrusted() else { return }

    let eventMask = (1 << CGEventType.keyDown.rawValue)
    let callback: CGEventTapCallBack = { proxy, type, event, refcon in
      guard let refcon else { return Unmanaged.passUnretained(event) }
      let manager = Unmanaged<ClipboardManager>.fromOpaque(refcon).takeUnretainedValue()
      return manager.handleEvent(proxy: proxy, type: type, event: event)
    }

    guard let tap = CGEvent.tapCreate(
      tap: .cgSessionEventTap,
      place: .headInsertEventTap,
      options: .defaultTap,
      eventsOfInterest: CGEventMask(eventMask),
      callback: callback,
      userInfo: Unmanaged.passUnretained(self).toOpaque()
    ) else {
      return
    }

    eventTap = tap
    runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

    if let runLoopSource {
      CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
      CGEvent.tapEnable(tap: tap, enable: true)
    }
  }

  func stop() {
    if let eventTap {
      CGEvent.tapEnable(tap: eventTap, enable: false)
    }

    if let runLoopSource {
      CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
    }

    eventTap = nil
    runLoopSource = nil
    teardownObservers()
  }

  func setHotkeysSuspended(_ suspended: Bool) {
    stateQueue.sync {
      hotkeysSuspended = suspended
    }
  }

  func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
      if let eventTap {
        CGEvent.tapEnable(tap: eventTap, enable: true)
      }
      return Unmanaged.passUnretained(event)
    }

    guard type == .keyDown else {
      return Unmanaged.passUnretained(event)
    }

    if isInjectingKeyEvent {
      return Unmanaged.passUnretained(event)
    }

    if stateQueue.sync(execute: { hotkeysSuspended }) {
      return Unmanaged.passUnretained(event)
    }

    if !AXIsProcessTrusted() {
      DispatchQueue.main.async { [weak self] in
        self?.stop()
      }
      return Unmanaged.passUnretained(event)
    }

    let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
    let flags = EnkoConfig.normalizeFlags(CGEventFlags(rawValue: event.flags.rawValue))

    let shortcuts = currentShortcuts()
    if keyCode == shortcuts.copyKeyCode && flags == shortcuts.copyFlags {
      handleCopyShortcut()
      return nil
    }

    if keyCode == shortcuts.pasteKeyCode && flags == shortcuts.pasteFlags {
      handlePasteShortcut()
      return nil
    }

    return Unmanaged.passUnretained(event)
  }

  func currentShortcuts() -> (copyKeyCode: CGKeyCode, copyFlags: CGEventFlags, pasteKeyCode: CGKeyCode, pasteFlags: CGEventFlags) {
    (
      EnkoConfig.copyShortcutKeyCode,
      EnkoConfig.normalizeFlags(EnkoConfig.copyShortcutFlags),
      EnkoConfig.pasteShortcutKeyCode,
      EnkoConfig.normalizeFlags(EnkoConfig.pasteShortcutFlags)
    )
  }
}
