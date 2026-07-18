import AppKit
import ApplicationServices

extension ClipboardManager {
  func captureSelectedTextFromAX() -> String? {
    let systemWide = AXUIElementCreateSystemWide()
    var focusedValue: AnyObject?
    let focusedResult = AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &focusedValue)
    guard focusedResult == .success,
          let focusedElement = focusedValue as! AXUIElement? else {
      return nil
    }

    var selectedTextValue: AnyObject?
    let selectedTextResult = AXUIElementCopyAttributeValue(focusedElement, kAXSelectedTextAttribute as CFString, &selectedTextValue)
    guard selectedTextResult == .success,
          let selectedText = selectedTextValue as? String,
          !selectedText.isEmpty else {
      return nil
    }

    return selectedText
  }

  func insertTextViaAX(_ text: String) -> Bool {
    let systemWide = AXUIElementCreateSystemWide()
    var focusedValue: AnyObject?
    let focusedResult = AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &focusedValue)
    guard focusedResult == .success,
          let focusedElement = focusedValue as! AXUIElement? else {
      return false
    }

    return AXUIElementSetAttributeValue(focusedElement, kAXSelectedTextAttribute as CFString, text as CFTypeRef) == .success
  }
}
