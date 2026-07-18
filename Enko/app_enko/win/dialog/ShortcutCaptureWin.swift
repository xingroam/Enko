import SwiftUI
import AppKit
import ApplicationServices

class ShortcutCaptureWin: NSObject, NSWindowDelegate {
  static let s = ShortcutCaptureWin()

  private var window: NSWindow?
  private var host: NSHostingController<AnyView>?
  private var onSave: ((CGKeyCode?, CGEventFlags) -> Void)?
  private var onCancel: (() -> Void)?
  private var completionHandled = false

  private override init() {
    super.init()
  }

  func show(
    title: String,
    initialKeyCode: CGKeyCode?,
    initialFlags: CGEventFlags,
    onSave: @escaping (CGKeyCode?, CGEventFlags) -> Void,
    onCancel: @escaping () -> Void
  ) {
    closeWindow(notifyCancel: false)

    self.onSave = onSave
    self.onCancel = onCancel
    completionHandled = false

    host = NSHostingController(
      rootView: AnyView(
        ShortcutCaptureView(
          title: title,
          initialKeyCode: initialKeyCode,
          initialFlags: initialFlags,
          onSave: { [weak self] keyCode, flags in
            self?.handleSave(keyCode: keyCode, flags: flags)
          },
          onCancel: { [weak self] in
            self?.handleCancel()
          }
        )
      )
    )

    guard let host else { return }
    let window = NSWindow(contentViewController: host)
    window.styleMask = [.titled, .closable, .fullSizeContentView]
    window.title = ""
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.isMovableByWindowBackground = true
    window.isReleasedWhenClosed = false
    window.isOpaque = false
    window.backgroundColor = .clear
    window.level = .floating
    window.center()
    window.delegate = self

    self.window = window

    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  func windowWillClose(_ notification: Notification) {
    if !completionHandled {
      onCancel?()
    }
    cleanup()
  }

  private func handleSave(keyCode: CGKeyCode?, flags: CGEventFlags) {
    completionHandled = true
    onSave?(keyCode, flags)
    closeWindow(notifyCancel: false)
  }

  private func handleCancel() {
    completionHandled = true
    onCancel?()
    closeWindow(notifyCancel: false)
  }

  private func closeWindow(notifyCancel: Bool) {
    if notifyCancel, !completionHandled {
      onCancel?()
    }
    window?.orderOut(nil)
    window?.close()
  }

  private func cleanup() {
    window?.delegate = nil
    window?.contentViewController = nil
    window = nil
    host = nil
    onSave = nil
    onCancel = nil
    completionHandled = false
  }
}
