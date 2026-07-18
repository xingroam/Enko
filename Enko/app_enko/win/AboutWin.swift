import SwiftUI
import AppKit

class AboutWin: NSObject, NSWindowDelegate {
  static let s = AboutWin()

  private var window: NSPanel?
  private var host: NSHostingController<AnyView>?

  private override init() {
    super.init()
  }

  func show() {
    if let existingWindow = window {
      existingWindow.makeKeyAndOrderFront(nil)
      NSApp.activate(ignoringOtherApps: true)
      return
    }

    host = NSHostingController(
      rootView: AnyView(
        AboutTabView()
      )
    )
    guard let host else { return }
    if #available(macOS 13.0, *) {
      host.sizingOptions = [.preferredContentSize]
    }
    let w = NSPanel(
      contentRect: NSRect(x: 0, y: 0, width: 420, height: 300),
      styleMask: [.titled, .closable, .utilityWindow],
      backing: .buffered,
      defer: false
    )
    w.contentViewController = host

    w.title = ""
    w.isFloatingPanel = false
    w.hidesOnDeactivate = false
    w.isMovableByWindowBackground = false
    w.isOpaque = true
    w.backgroundColor = .windowBackgroundColor
    w.center()
    w.delegate = self

    window = w
    w.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  func windowWillClose(_ notification: Notification) {
    guard let closingWindow = notification.object as? NSWindow, closingWindow === window else { return }
    window?.delegate = nil
    window?.contentViewController = nil
    window = nil
    host = nil
  }
}
