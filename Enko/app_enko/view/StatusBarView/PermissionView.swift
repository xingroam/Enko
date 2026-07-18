import SwiftUI

struct PermissionView: View {
  @StateObject private var languageManager = LanguageManager.s
  let requestPermission: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(languageManager.localizedString("enko.permission.accessibility.title"))
        .font(.system(size: 14, weight: .bold))
        .foregroundStyle(.primary)

      Text(languageManager.localizedString("enko.permission.accessibility.message"))
        .font(.system(size: 12, weight: .regular))
        .foregroundStyle(.primary)
        .fixedSize(horizontal: false, vertical: true)

      Button(action: requestPermission) {
        HStack(spacing: 6) {
          Image(systemName: "hand.raised")
          Text(languageManager.localizedString("enko.permission.accessibility.button"))
            .font(.system(size: 12, weight: .regular))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity, minHeight: 28)
      .background(Color.accentColor)
      .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
      .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
    .padding(12)
    .background(Color.red.opacity(0.3))
    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
  }
}
