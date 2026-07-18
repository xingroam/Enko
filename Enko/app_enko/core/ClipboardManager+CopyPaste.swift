import AppKit
import ApplicationServices

extension ClipboardManager {
  func handleCopyShortcut() {
    processingQueue.async { [weak self] in
      guard let self else { return }
      guard AXIsProcessTrusted() else { return }
      if let selectedText = captureSelectedTextFromAX(), !selectedText.isEmpty {
        if storeEncryptedText(selectedText) {
          DispatchQueue.main.async {
            self.onSecureCopy?()
          }
        }
      }
    }
  }

  func handlePasteShortcut() {
    processingQueue.async { [weak self] in
      guard let self else { return }
      let consume = EnkoConfig.clearSecureCacheAfterPaste
      guard let snapshot = encryptedPayloadSnapshot(consume: consume),
            let secureText = decryptedText(from: snapshot),
            !secureText.isEmpty else { return }

      DispatchQueue.main.async {
        if AXIsProcessTrusted() && self.insertTextViaAX(secureText) {
          return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
          self.sendSimulatedTextInputWhenModifiersReleased(secureText)
        }
      }

      guard !consume else { return }

      processingQueue.asyncAfter(deadline: .now() + 0.35) { [weak self] in
        guard let self else { return }
        _ = self.storeEncryptedText(secureText)
      }
    }
  }
}
