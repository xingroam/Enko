import SwiftUI

struct PasteSettingView: View {
  @StateObject private var languageManager = LanguageManager.s
  @State private var clearSecureCacheAfterPaste = EnkoConfig.clearSecureCacheAfterPaste
  @State private var clearSecureCacheOnSleep = EnkoConfig.clearSecureCacheOnSleep
  @State private var pasteTypingInterval = EnkoConfig.pasteTypingInterval

  var body: some View {
    StatusBarSettingGroup(title: languageManager.localizedString("enko.settings.group.paste")) {
      StatusBarSettingSliderRow(
        title: languageManager.localizedString("enko.settings.paste.speed"),
        valueText: "\(Int(round(pasteTypingInterval * 1000))) ms",
        value: Binding(
          get: { pasteTypingInterval },
          set: {
            pasteTypingInterval = EnkoConfig.clampPasteTypingInterval($0)
            EnkoConfig.pasteTypingInterval = pasteTypingInterval
          }
        ),
        range: 0.001...0.100,
        step: 0.001
      )

      StatusBarSettingToggleRow(
        title: languageManager.localizedString("enko.settings.shortcuts.clear_after_paste"),
        isOn: Binding(
          get: { clearSecureCacheAfterPaste },
          set: {
            clearSecureCacheAfterPaste = $0
            EnkoConfig.clearSecureCacheAfterPaste = $0
          }
        )
      )

      StatusBarSettingToggleRow(
        title: languageManager.localizedString("enko.settings.shortcuts.clear_on_sleep"),
        isOn: Binding(
          get: { clearSecureCacheOnSleep },
          set: {
            clearSecureCacheOnSleep = $0
            EnkoConfig.clearSecureCacheOnSleep = $0
          }
        )
      )
    }
    .onAppear {
      clearSecureCacheAfterPaste = EnkoConfig.clearSecureCacheAfterPaste
      clearSecureCacheOnSleep = EnkoConfig.clearSecureCacheOnSleep
      pasteTypingInterval = EnkoConfig.pasteTypingInterval
    }
  }
}
