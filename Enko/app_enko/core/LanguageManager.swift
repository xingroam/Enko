import Foundation
import Combine

struct LanguageOption: Identifiable, Hashable {
  let id = UUID()
  let code: String
  let name: String

  func hash(into hasher: inout Hasher) {
    hasher.combine(code)
  }

  static func == (lhs: LanguageOption, rhs: LanguageOption) -> Bool {
    lhs.code == rhs.code
  }
}

class LanguageManager: ObservableObject {
  static let s = LanguageManager()

  let supportedLanguages: [LanguageOption] = [
    LanguageOption(code: "en", name: "English"),
    LanguageOption(code: "zh-Hans", name: "简体中文"),
    LanguageOption(code: "zh-Hant", name: "繁體中文")
  ]

  @Published var currentLanguage: String {
    didSet {
      setAppleLanguages([currentLanguage])
    }
  }

  private init() {
    let appleLanguages = EnkoConfig.appLanguages
    if let firstLanguage = appleLanguages.first {
      currentLanguage = Self.normalizedLanguageCode(from: firstLanguage)
    } else {
      let systemCode = Locale.preferredLanguages.first ?? "en"
      currentLanguage = Self.normalizedLanguageCode(from: systemCode)
      setAppleLanguages([currentLanguage])
    }
  }

  func localizedString(_ key: String) -> String {
    if let bundlePath = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
       let bundle = Bundle(path: bundlePath) {
      return NSLocalizedString(key, tableName: nil, bundle: bundle, value: key, comment: "")
    }
    return NSLocalizedString(key, comment: "")
  }

  func setLanguage(_ code: String) {
    let normalized = Self.normalizedLanguageCode(from: code)
    if normalized == currentLanguage { return }
    currentLanguage = normalized
  }

  private func setAppleLanguages(_ languages: [String]) {
    EnkoConfig.appLanguages = languages
    NotificationCenter.default.post(name: NSNotification.Name("AppleLanguagesDidChange"), object: nil)
  }

  private static func normalizedLanguageCode(from code: String) -> String {
    if code.hasPrefix("zh-Hans") || code == "zh-CN" || code == "zh-SG" { return "zh-Hans" }
    if code.hasPrefix("zh-Hant") || code == "zh-TW" || code == "zh-HK" || code == "zh-MO" { return "zh-Hant" }
    if code.hasPrefix("zh") {
      let region = Locale.current.region?.identifier ?? ""
      return (region == "TW" || region == "HK" || region == "MO") ? "zh-Hant" : "zh-Hans"
    }
    if code.hasPrefix("en") { return "en" }
    return "en"
  }
}