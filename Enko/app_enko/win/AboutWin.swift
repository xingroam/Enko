import SwiftUI
import AppKit

class AboutWin: NSObject, NSWindowDelegate {
  static let s = AboutWin()

  private var window: NSWindow?
  private var hostingController: NSHostingController<AboutView>?

  private override init() {
    super.init()
  }

  func show() {
    if let existingWindow = window, existingWindow.isVisible {
      existingWindow.makeKeyAndOrderFront(nil)
      NSApp.activate(ignoringOtherApps: true)
      return
    }
    let view = AboutView()
    hostingController = NSHostingController(rootView: view)
    guard let host = hostingController else { return }
    window = NSWindow(contentViewController: host)
    guard let w = window else { return }
    w.title = ""
    w.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
    w.titleVisibility = .hidden
    w.titlebarAppearsTransparent = true
    w.isOpaque = false
    w.backgroundColor = .clear
    w.isMovableByWindowBackground = true
    w.standardWindowButton(.zoomButton)?.isHidden = true
    w.standardWindowButton(.miniaturizeButton)?.isHidden = false
    w.level = .popUpMenu
    w.delegate = self
    let size = host.view.intrinsicContentSize
    if size.width > 0, size.height > 0 {
      w.setContentSize(size)
    }
    ScreenManager.s.Center(w, winCenter: true)
    w.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  func windowWillClose(_ notification: Notification) {
    guard let closingWindow = notification.object as? NSWindow, closingWindow === window else { return }
    window?.delegate = nil
    window?.contentViewController = nil
    window = nil
    hostingController = nil
  }
}
