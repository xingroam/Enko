import AppKit
import SwiftUI
import QuartzCore

class StatusBarView: NSObject {
  private let statusItem: NSStatusItem
  private let languageManager = LanguageManager.s
  private var languageObserver: NSObjectProtocol?

  override init() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    super.init()
    setupStatusBar()
    updateMenu()
    languageObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name("AppleLanguagesDidChange"), object: nil, queue: .main) { [weak self] _ in
      self?.updateMenu()
    }
  }

  deinit {
    if let languageObserver {
      NotificationCenter.default.removeObserver(languageObserver)
    }
  }

  private func setupStatusBar() {
    guard let button = statusItem.button else { return }
    if let image = NSImage(named: "StatusBarIcon") {
      image.size = NSSize(width: 18, height: 18)
      button.image = image
      button.image?.isTemplate = true
    }
  }

  private func updateMenu() {
    statusItem.menu = nil

    let menu = NSMenu()
    menu.autoenablesItems = false

    let appInfoItem = NSMenuItem(title: languageManager.localizedString("enko.settings.tab.about"), action: #selector(showAboutWin), keyEquivalent: "")
    appInfoItem.target = self

    menu.addItem(settingMenuItem())

    menu.addItem(NSMenuItem.separator())

    let updateItem = NSMenuItem(title: languageManager.localizedString("enko.menu.check_updates"), action: #selector(checkUpdate), keyEquivalent: "")
    updateItem.target = self
    menu.addItem(updateItem)

    menu.addItem(appInfoItem)

    menu.addItem(NSMenuItem.separator())

    let quitItem = NSMenuItem(title: languageManager.localizedString("enko.menu.quit"), action: #selector(quit), keyEquivalent: "q")
    quitItem.keyEquivalentModifierMask = [.command]
    quitItem.target = self
    menu.addItem(quitItem)

    statusItem.menu = menu
  }

  @objc private func showAboutWin() {
    AboutWin.s.show()
  }

  private func settingMenuItem() -> NSMenuItem {
    let item = NSMenuItem()
    item.isEnabled = true
    let content = SettingView()
    let hostingView = NSHostingView(rootView: content)
    hostingView.layoutSubtreeIfNeeded()
    hostingView.frame.size.height = ceil(hostingView.fittingSize.height)
    item.view = hostingView
    return item
  }

  @objc private func checkUpdate() {
    UpdateManager.s.checkForUpdates()
  }

  @objc private func quit() {
    NSApp.terminate(nil)
  }

  func showSecureCopyFeedback() {
    DispatchQueue.main.async {
      guard let button = self.statusItem.button else { return }
      button.contentTintColor = NSColor.systemGreen
      button.wantsLayer = true

      if let layer = button.layer {
        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.fromValue = 1.0
        pulse.toValue = 1.16
        pulse.duration = 0.10
        pulse.autoreverses = true
        layer.add(pulse, forKey: "enko.copy.pulse")
      }

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
        button.contentTintColor = NSColor.labelColor
      }
    }
  }
}
