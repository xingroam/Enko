import SwiftUI
import AppKit

struct ShortcutSettingView: View {
  private enum ShortcutTarget {
    case copy
    case paste
  }

  @StateObject private var languageManager = LanguageManager.s
  @State private var copyShortcutKeyCode = EnkoConfig.copyShortcutKeyCode
  @State private var copyShortcutFlags = EnkoConfig.copyShortcutFlags
  @State private var pasteShortcutKeyCode = EnkoConfig.pasteShortcutKeyCode
  @State private var pasteShortcutFlags = EnkoConfig.pasteShortcutFlags
  @State private var activeDialogTarget: ShortcutTarget = .copy

  private func openShortcutDialog(for target: ShortcutTarget) {
    activeDialogTarget = target
    ClipboardManager.s.setHotkeysSuspended(true)
    ShortcutCaptureWin.s.show(
      title: activeDialogTitle,
      initialKeyCode: activeShortcutKeyCode,
      initialFlags: activeShortcutFlags,
      onSave: { keyCode, flags in
        saveDialogShortcut(keyCode: keyCode, flags: flags)
        ClipboardManager.s.setHotkeysSuspended(false)
      },
      onCancel: {
        ClipboardManager.s.setHotkeysSuspended(false)
      }
    )
  }

  private func applyRecordedShortcut(target: ShortcutTarget, keyCode: CGKeyCode, flags: CGEventFlags) {
    if target == .copy {
      copyShortcutKeyCode = keyCode
      copyShortcutFlags = flags
      EnkoConfig.copyShortcutKeyCode = keyCode
      EnkoConfig.copyShortcutFlags = flags
    } else {
      pasteShortcutKeyCode = keyCode
      pasteShortcutFlags = flags
      EnkoConfig.pasteShortcutKeyCode = keyCode
      EnkoConfig.pasteShortcutFlags = flags
    }
  }

  private var copyShortcutDisplay: String {
    return Keyboard.shortNameShortcut(keyCode: copyShortcutKeyCode, flags: copyShortcutFlags)
  }

  private var pasteShortcutDisplay: String {
    return Keyboard.shortNameShortcut(keyCode: pasteShortcutKeyCode, flags: pasteShortcutFlags)
  }

  private var activeShortcutKeyCode: CGKeyCode? {
    switch activeDialogTarget {
    case .copy:
      return copyShortcutKeyCode == .disabled ? nil : copyShortcutKeyCode
    case .paste:
      return pasteShortcutKeyCode == .disabled ? nil : pasteShortcutKeyCode
    }
  }

  private var activeShortcutFlags: CGEventFlags {
    switch activeDialogTarget {
    case .copy:
      return copyShortcutFlags
    case .paste:
      return pasteShortcutFlags
    }
  }

  private var activeDialogTitle: String {
    switch activeDialogTarget {
    case .copy:
      return shortcutDialogTitle(for: "enko.settings.shortcuts.copy")
    case .paste:
      return shortcutDialogTitle(for: "enko.settings.shortcuts.paste")
    }
  }

  private func shortcutDialogTitle(for key: String) -> String {
    let actionTitle = languageManager.localizedString(key)
    let groupTitle = languageManager.localizedString("enko.settings.group.shortcuts")
    let needsSpace = actionTitle.canBeConverted(to: .ascii) && groupTitle.canBeConverted(to: .ascii)
    return needsSpace ? "\(actionTitle) \(groupTitle)" : actionTitle + groupTitle
  }

  private func saveDialogShortcut(keyCode: CGKeyCode?, flags: CGEventFlags) {
    if let keyCode {
      applyRecordedShortcut(target: activeDialogTarget, keyCode: keyCode, flags: flags)
      return
    }

    if activeDialogTarget == .copy {
      copyShortcutKeyCode = .disabled
      copyShortcutFlags = .disabled
      EnkoConfig.copyShortcutKeyCode = .disabled
      EnkoConfig.copyShortcutFlags = .disabled
    } else {
      pasteShortcutKeyCode = .disabled
      pasteShortcutFlags = .disabled
      EnkoConfig.pasteShortcutKeyCode = .disabled
      EnkoConfig.pasteShortcutFlags = .disabled
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      StatusBarSettingGroup(title: languageManager.localizedString("enko.settings.group.shortcuts")) {
        StatusBarSettingShortcutRow(
          title: languageManager.localizedString("enko.settings.shortcuts.copy"),
          value: copyShortcutDisplay,
          action: { openShortcutDialog(for: .copy) }
        )

        StatusBarSettingShortcutRow(
          title: languageManager.localizedString("enko.settings.shortcuts.paste"),
          value: pasteShortcutDisplay,
          action: { openShortcutDialog(for: .paste) }
        )
      }

      PasteSettingView()
    }
    .onAppear {
      copyShortcutKeyCode = EnkoConfig.copyShortcutKeyCode
      copyShortcutFlags = EnkoConfig.copyShortcutFlags
      pasteShortcutKeyCode = EnkoConfig.pasteShortcutKeyCode
      pasteShortcutFlags = EnkoConfig.pasteShortcutFlags
    }
  }
}
