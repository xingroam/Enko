import SwiftUI

struct AppSettingView: View {
  @StateObject private var languageManager = LanguageManager.s
  @State private var launchAtLogin = StartupManager.s.isAppInStartupItems()

  let showLanguagePage: () -> Void

  private var appName: String {
    EnkoInfo.appName
  }

  private var appVersion: String {
    if !EnkoInfo.version.isEmpty {
      return EnkoInfo.version
    }
    return EnkoInfo.build
  }

  private var appGroupTitle: String {
    appVersion.isEmpty ? appName : "\(appName) \(appVersion)"
  }

  private func setLaunchAtLogin(_ enabled: Bool) {
    if enabled {
      StartupManager.s.addAppToStartupItems()
    } else {
      StartupManager.s.removeAppFromStartupItems()
    }
    launchAtLogin = StartupManager.s.isAppInStartupItems()
  }

  var body: some View {
    StatusBarSettingGroup(title: appGroupTitle) {
      StatusBarSettingNavigationRow(
        title: languageManager.localizedString("enko.settings.language"),
        value: languageManager.supportedLanguages.first(where: { $0.code == languageManager.currentLanguage })?.name ?? languageManager.currentLanguage,
        action: showLanguagePage
      )

      StatusBarSettingToggleRow(
        title: languageManager.localizedString("enko.settings.launch_at_login"),
        isOn: Binding(get: { launchAtLogin }, set: { setLaunchAtLogin($0) })
      )
    }
    .onAppear {
      launchAtLogin = StartupManager.s.isAppInStartupItems()
    }
  }
}
