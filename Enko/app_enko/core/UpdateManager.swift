import AppKit

#if canImport(Sparkle)
import Sparkle
#endif

final class UpdateManager: NSObject {
  static let s = UpdateManager()

  private let languageManager = LanguageManager.s

  #if canImport(Sparkle)
  private let updaterController: SPUStandardUpdaterController
  #endif

  private override init() {
    #if canImport(Sparkle)
    updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    #endif
    super.init()
  }

  func checkForUpdates() {
    DispatchQueue.main.async {
      #if canImport(Sparkle)
      self.updaterController.checkForUpdates(nil)
      #else
      let alert = NSAlert()
      alert.messageText = self.languageManager.localizedString("enko.update.title")
      alert.informativeText = self.languageManager.localizedString("enko.update.message")
      alert.addButton(withTitle: self.languageManager.localizedString("enko.common.ok"))
      alert.runModal()
      #endif
    }
  }
}
