import SwiftUI
import AppKit
import ApplicationServices

struct SettingView: View {
  private enum Page {
    case main
    case language
  }

  @State private var page: Page = .main
  @State private var mainPageHeight: CGFloat = 0
  @State private var hasAccessibilityPermission: Bool = AXIsProcessTrusted()

  private func refreshAccessibilityPermission() {
    let trusted = AXIsProcessTrusted()
    let wasTrusted = hasAccessibilityPermission
    hasAccessibilityPermission = trusted
    if trusted != wasTrusted {
      page = .main
      mainPageHeight = 0
    }
    if trusted {
      ClipboardManager.s.start()
    } else {
      ClipboardManager.s.stop()
    }
  }

  private func requestAccessibilityPermission() {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
    AXIsProcessTrustedWithOptions(options)
    refreshAccessibilityPermission()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      refreshAccessibilityPermission()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
      refreshAccessibilityPermission()
    }
  }

  var body: some View {
    Group {
      ZStack(alignment: .topLeading) {
        if page == .main {
          VStack(alignment: .leading, spacing: 10) {
            AppSettingView(showLanguagePage: { page = .language })

            if hasAccessibilityPermission {
              ShortcutSettingView()
              DonationView()
            } else {
              PermissionView(requestPermission: requestAccessibilityPermission)
            }
          }
          .background(
            GeometryReader { geometry in
              Color.clear.preference(key: StatusBarMainPageHeightKey.self, value: geometry.size.height)
            }
          )
        }

        if page == .language {
          StatusBarLanguageSettingPage(
            back: { page = .main },
            complete: { page = .main },
            containerHeight: mainPageHeight
          )
        }
      }
    }
    .onAppear {
      refreshAccessibilityPermission()
    }
    .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
      refreshAccessibilityPermission()
    }
    .onPreferenceChange(StatusBarMainPageHeightKey.self) { mainPageHeight = $0 }
    .frame(maxWidth: .infinity, alignment: .topLeading)
  }
}

private struct StatusBarMainPageHeightKey: PreferenceKey {
  static var defaultValue: CGFloat = 0

  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }
}

struct StatusBarMenuWindowContentView: View {
  @StateObject private var languageManager = LanguageManager.s

  private func dismissStatusBarMenu() {
    NSApp.sendAction(#selector(NSMenu.cancelTracking), to: nil, from: nil)
    if let keyWindow = NSApp.keyWindow {
      keyWindow.orderOut(nil)
      keyWindow.close()
    }
  }

  var body: some View {
    VStack(spacing: 10) {
      SettingView()

      HStack(spacing: 10) {
        Menu {
          Button(languageManager.localizedString("enko.menu.check_updates")) {
            dismissStatusBarMenu()
            DispatchQueue.main.async {
              UpdateManager.s.checkForUpdates()
            }
          }
          Button(languageManager.localizedString("enko.settings.tab.about")) {
            dismissStatusBarMenu()
            DispatchQueue.main.async {
              AboutWin.s.show()
            }
          }
        } label: {
          Image(systemName: "ellipsis.circle")
            .font(.system(size: 16, weight: .semibold))
            .frame(width: 24, height: 24)
            .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .accessibilityLabel(Text("More"))

        Spacer(minLength: 0)

        Button {
          NSApp.terminate(nil)
        } label: {
          Image(systemName: "power")
            .font(.system(size: 14, weight: .semibold))
            .frame(width: 24, height: 24)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .accessibilityLabel(Text(languageManager.localizedString("enko.menu.quit")))
      }
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 10)
    .frame(width: 300, alignment: .topLeading)
  }
}

private struct StatusBarLanguageSettingPage: View {
  @StateObject private var languageManager = LanguageManager.s
  let back: () -> Void
  let complete: () -> Void
  let containerHeight: CGFloat

  private func restartApplication() {
    let bundlePath = Bundle.main.bundlePath
    let process = Process()
    process.launchPath = "/usr/bin/open"
    process.arguments = [bundlePath]
    process.launch()
    NSApp.terminate(nil)
  }

  private func showRestartRequiredAlert() {
    let alert = NSAlert()
    alert.messageText = languageManager.localizedString("enko.settings.language.changed.message")
    alert.informativeText = languageManager.localizedString("enko.settings.language.changed.info")
    alert.addButton(withTitle: languageManager.localizedString("enko.settings.language.changed.restart_now"))
    alert.addButton(withTitle: languageManager.localizedString("enko.settings.language.changed.later"))
    let result = alert.runModal()
    if result == .alertFirstButtonReturn {
      restartApplication()
    }
  }

  private func selectLanguage(_ code: String) {
    guard code != languageManager.currentLanguage else {
      complete()
      return
    }
    languageManager.setLanguage(code)
    complete()
    DispatchQueue.main.async {
      showRestartRequiredAlert()
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Button(action: back) {
        HStack(spacing: 5) {
          Image(systemName: "chevron.left")
            .font(.system(size: 12, weight: .semibold))
          Text("Back")
            .font(.system(size: 13, weight: .medium))
          Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(Rectangle())

      GeometryReader { geometry in
        StatusBarStretchSettingGroup(title: languageManager.localizedString("enko.settings.language")) {
          ScrollView {
            VStack(spacing: 0) {
              ForEach(languageManager.supportedLanguages) { option in
                Button {
                  selectLanguage(option.code)
                } label: {
                  HStack(spacing: 10) {
                    Text(option.name)
                      .font(.system(size: 13, weight: .medium))
                      .foregroundStyle(.primary)
                    Spacer(minLength: 12)
                    if option.code == languageManager.currentLanguage {
                      Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                    }
                  }
                  .padding(.horizontal, 12)
                  .padding(.vertical, 10)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
              }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
      }
      .frame(maxHeight: .infinity, alignment: .top)
    }
    .frame(maxWidth: .infinity, alignment: .topLeading)
    .frame(height: containerHeight > 0 ? containerHeight : nil, alignment: .top)
    .frame(maxHeight: .infinity, alignment: .top)
  }
}

struct StatusBarSettingGroup<Content: View>: View {
  let title: String
  @ViewBuilder let content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title)
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(.secondary)

      VStack(spacing: 0) {
        content
      }
      .background(.regularMaterial)
      .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 10, style: .continuous)
          .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
      )
    }
  }
}

struct StatusBarStretchSettingGroup<Content: View>: View {
  let title: String
  @ViewBuilder let content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title)
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(.secondary)

      VStack(spacing: 0) {
        content
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .background(.regularMaterial)
      .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 10, style: .continuous)
          .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
      )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}

struct StatusBarSettingToggleRow: View {
  let title: String
  @Binding var isOn: Bool

  var body: some View {
    HStack(spacing: 10) {
      Text(title)
        .font(.system(size: 13, weight: .medium))
      Spacer(minLength: 12)
      StatusBarMenuSwitch(isOn: $isOn)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct StatusBarSettingSliderRow: View {
  let title: String
  let valueText: String
  @Binding var value: Double
  let range: ClosedRange<Double>
  let step: Double

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 10) {
        Text(title)
          .font(.system(size: 13, weight: .medium))
        Spacer(minLength: 12)
        Text(valueText)
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(.secondary)
      }

      Slider(value: $value, in: range)
        .controlSize(.small)
        .onChange(of: value) { _, newValue in
          guard step > 0 else { return }
          let quantized = (newValue / step).rounded() * step
          let clamped = min(max(quantized, range.lowerBound), range.upperBound)
          if abs(clamped - newValue) > 0.0000001 {
            value = clamped
          }
        }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct StatusBarMenuSwitch: View {
  @Binding var isOn: Bool

  var body: some View {
    Button {
      isOn.toggle()
    } label: {
      ZStack(alignment: isOn ? .trailing : .leading) {
        Capsule(style: .continuous)
          .fill(isOn ? Color(nsColor: .controlAccentColor) : Color(nsColor: .quaternaryLabelColor))
          .frame(width: 34, height: 20)
        Circle()
          .fill(Color.white)
          .frame(width: 16, height: 16)
          .padding(2)
          .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 0.5)
      }
      .animation(.easeInOut(duration: 0.16), value: isOn)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(Text("Toggle"))
    .accessibilityValue(Text(isOn ? "On" : "Off"))
  }
}

struct StatusBarSettingNavigationRow: View {
  let title: String
  let value: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 10) {
        Text(title)
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(.primary)
        Spacer(minLength: 12)
        Text(value)
          .font(.system(size: 13, weight: .regular))
          .foregroundStyle(.secondary)
        Image(systemName: "chevron.right")
          .font(.system(size: 11, weight: .semibold))
          .foregroundStyle(.secondary)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 10)
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}

struct StatusBarSettingShortcutRow: View {
  let title: String
  let value: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 10) {
        Text(title)
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(.primary)
        Spacer(minLength: 12)
        Text(value)
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(.secondary)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 10)
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}

struct StatusBarSettingInfoRow: View {
  let text: String

  var body: some View {
    HStack(spacing: 10) {
      Text(text)
        .font(.system(size: 12, weight: .regular))
        .foregroundStyle(.secondary)
      Spacer(minLength: 0)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
