import AppKit
import Combine

final class EnkoStatusBarState: ObservableObject {
  static let s = EnkoStatusBarState()

  @Published var copyFeedbackToken: Int = 0

  private init() {}

  func triggerCopyFeedback() {
    DispatchQueue.main.async {
      self.copyFeedbackToken &+= 1
    }
  }
}

class Enko {
  static let s = Enko()

  private let clipboardManager = ClipboardManager.s

  private init() {}

  func boot() {
    NSApp.setActivationPolicy(.accessory)
    _ = UpdateManager.s
    clipboardManager.onSecureCopy = {
      EnkoStatusBarState.s.triggerCopyFeedback()
    }
    clipboardManager.start()
  }

  func end() {
    clipboardManager.onSecureCopy = nil
    clipboardManager.stop()
  }
}
