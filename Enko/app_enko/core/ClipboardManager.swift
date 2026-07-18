import AppKit
import ApplicationServices
import Carbon.HIToolbox
import CryptoKit

final class ClipboardManager {
  static let s = ClipboardManager()

  var onSecureCopy: (() -> Void)?

  let stateQueue = DispatchQueue(label: "com.potor.Enko.clipboard.state")
  var encryptedPayloadData: Data?
  var encryptedPayloadKeyData: Data?
  var encryptedSessionWrapKeyData: Data?
  var fallbackSessionWrapKey = SymmetricKey(size: .bits256)

  var eventTap: CFMachPort?
  var runLoopSource: CFRunLoopSource?
  var appActiveObserver: NSObjectProtocol?
  var workspaceSleepObserver: NSObjectProtocol?
  var workspaceSessionResignObserver: NSObjectProtocol?
  var screenLockObserver: NSObjectProtocol?
  let processingQueue = DispatchQueue(label: "com.potor.Enko.clipboard.processing")
  var isInjectingKeyEvent = false
  var hotkeysSuspended = false

  private init() {
    refreshSessionWrapKey()
  }

  deinit {
    stop()
  }
}
