import SwiftUI
import AppKit

struct AboutView: View {
  @StateObject private var languageManager = LanguageManager.s

  private var appDescription: String {
    languageManager.localizedString("enko.settings.about.description")
  }

  private var currentYear: Int {
    Calendar.current.component(.year, from: Date())
  }

  private var appName: String {
    EnkoInfo.appName
  }

  private var appVersionLabel: String {
    let version = EnkoInfo.version
    let build = EnkoInfo.build
    if !version.isEmpty, !build.isEmpty {
      return String(format: languageManager.localizedString("enko.settings.about.version"), version, build)
    }
    if !version.isEmpty {
      return String(format: languageManager.localizedString("enko.settings.about.version_only"), version)
    }
    return ""
  }

  private var appIcon: NSImage {
    NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath)
  }

  private func openGitHub() {
    guard let url = URL(string: "https://github.com/potor-com/Enko") else { return }
    NSWorkspace.shared.open(url)
  }

  private func openContributors() {
    guard let url = URL(string: "https://github.com/potor-com/Enko/graphs/contributors") else { return }
    NSWorkspace.shared.open(url)
  }

  private func openFeedback() {
    guard let url = URL(string: "https://github.com/potor-com/Enko/issues/new/choose") else { return }
    NSWorkspace.shared.open(url)
  }

  private func openPrivacyPolicy() {
    guard let url = URL(string: "https://github.com/potor-com/Enko/blob/main/docs/PRIVACY.md") else { return }
    NSWorkspace.shared.open(url)
  }

  private func openDisclaimer() {
    guard let url = URL(string: "https://github.com/potor-com/Enko/blob/main/docs/DISCLAIMER.md") else { return }
    NSWorkspace.shared.open(url)
  }

  var body: some View {
    VStack(spacing: 15) {
      VStack(spacing: 5) {
        Image(nsImage: appIcon)
          .resizable()
          .interpolation(.high)
          .frame(width: 120, height: 120)
        Text(appName)
          .font(.system(size: 26))
          .fontWeight(.semibold)
        if !appVersionLabel.isEmpty {
          Text(appVersionLabel)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(.primary)
        }
      }
      .frame(maxWidth: .infinity, alignment: .center)

      Text(appDescription)
        .font(.system(size: 12))
        .fontWeight(.semibold)
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
        .foregroundStyle(.primary)

      HStack(spacing: 5) {
        Button {
          openGitHub()
        } label: {
          Label(languageManager.localizedString("enko.settings.about.github"), systemImage: "link")
        }
        .buttonStyle(.bordered)

        Button {
          openContributors()
        } label: {
          Label(languageManager.localizedString("enko.settings.about.contributors"), systemImage: "person.3.fill")
        }
        .buttonStyle(.bordered)

        Button {
          openFeedback()
        } label: {
          Label(languageManager.localizedString("enko.settings.about.feedback"), systemImage: "bubble.left.and.bubble.right")
        }
        .buttonStyle(.bordered)
      }
      .frame(maxWidth: .infinity, alignment: .center)

      VStack(spacing: 5) {
        HStack(spacing: 5) {
          Button {
            openPrivacyPolicy()
          } label: {
            Text(languageManager.localizedString("enko.settings.about.privacy"))
              .font(.system(size: 12))
              .foregroundColor(.accentColor)
          }
          .buttonStyle(.plain)

          Button {
            openDisclaimer()
          } label: {
            Text(languageManager.localizedString("enko.settings.about.disclaimer"))
              .font(.system(size: 12))
              .foregroundColor(.accentColor)
          }
          .buttonStyle(.plain)
        }

        Text("© \(String(currentYear)) Potor")
          .font(.system(size: 12))
          .foregroundStyle(.primary)
      }
      .frame(maxWidth: .infinity, alignment: .center)
    }
    .padding(.horizontal, 40)
    .padding(.top, 40)
    .padding(.bottom, 20)
    .background(BlurredBackground(material: .underWindowBackground, blendingMode: .behindWindow, blur: 1.0))
    .compositingGroup()
    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    .ignoresSafeArea(edges: .top)
  }
}
