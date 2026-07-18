import AppKit
import Carbon.HIToolbox

extension ClipboardManager {
  func sendSimulatedTextInput(_ text: String) {
    guard let source = CGEventSource(stateID: .combinedSessionState) else { return }
    guard !text.isEmpty else { return }
    isInjectingKeyEvent = true

    let baseInterval = EnkoConfig.pasteTypingInterval
    let newlineExtraInterval: TimeInterval = 0.010
    var delay: TimeInterval = 0

    for character in text {
      let segment = String(character)
      let scalars = Array(segment.utf16)
      if scalars.isEmpty {
        continue
      }

      let isLineBreak = segment == "\n" || segment == "\r"

      DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        if isLineBreak {
          self.postReturnKey(source: source)
        } else {
          self.postUnicodeScalars(scalars, source: source)
        }
      }

      delay += baseInterval
      if scalars.contains(10) || scalars.contains(13) {
        delay += newlineExtraInterval
      }
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.04) {
      self.isInjectingKeyEvent = false
    }
  }

  func sendSimulatedTextInputWhenModifiersReleased(_ text: String, attempt: Int = 0) {
    let activeModifiers = NSEvent.modifierFlags.intersection([.command, .option, .control, .shift])
    if !activeModifiers.isEmpty && attempt < 20 {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
        self.sendSimulatedTextInputWhenModifiersReleased(text, attempt: attempt + 1)
      }
      return
    }
    sendSimulatedTextInput(text)
  }

  func postUnicodeScalars(_ scalars: [unichar], source: CGEventSource) {
    var mutableScalars = scalars
    if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
       let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) {
      keyDown.flags = []
      keyUp.flags = []
      keyDown.keyboardSetUnicodeString(stringLength: mutableScalars.count, unicodeString: &mutableScalars)
      keyUp.keyboardSetUnicodeString(stringLength: mutableScalars.count, unicodeString: &mutableScalars)
      keyDown.post(tap: CGEventTapLocation.cghidEventTap)
      keyUp.post(tap: CGEventTapLocation.cghidEventTap)
    }
  }

  func postReturnKey(source: CGEventSource) {
    let keyCode = CGKeyCode(kVK_Return)
    if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
       let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) {
      keyDown.flags = []
      keyUp.flags = []
      keyDown.post(tap: CGEventTapLocation.cghidEventTap)
      keyUp.post(tap: CGEventTapLocation.cghidEventTap)
    }
  }

  func postSystemPasteShortcut() {
    isInjectingKeyEvent = true
    postShortcut(keyCode: CGKeyCode(kVK_ANSI_V), flags: .maskCommand)

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
      self.isInjectingKeyEvent = false
    }
  }

  func postSystemCopyShortcut() {
    isInjectingKeyEvent = true
    postShortcut(keyCode: CGKeyCode(kVK_ANSI_C), flags: .maskCommand)

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
      self.isInjectingKeyEvent = false
    }
  }

  func postShortcut(keyCode: CGKeyCode, flags: CGEventFlags) {
    guard let source = CGEventSource(stateID: .combinedSessionState) else { return }
    if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
       let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) {
      keyDown.flags = flags
      keyUp.flags = flags
      keyDown.post(tap: CGEventTapLocation.cghidEventTap)
      keyUp.post(tap: CGEventTapLocation.cghidEventTap)
    }
  }
}
