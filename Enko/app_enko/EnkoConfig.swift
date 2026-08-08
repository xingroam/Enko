import AppKit
import Carbon.HIToolbox
import CryptoKit
import Security

struct EnkoInfo {
  static let displayName = { Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "" }()
  static let name = { Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "App" }()
  static let appName = { displayName.isEmpty ? name : displayName }()
  static let version = { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "" }()
  static let build = { Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "" }()
  static let bundleIdentifier = { Bundle.main.bundleIdentifier ?? "" }()
  static let bundleIdentifierLowercased = { Bundle.main.bundleIdentifier?.lowercased() ?? "" }()

  static let statusBarCopyAnimationDuration: TimeInterval = 0.2

  static let enkoJson = "https://xingroam.github.io/Enko/enko.json"
  static let enkoJsonHour = 24
}

struct EnkoDefine {
  static let defaultAppLanguages: [String] = []
  static let defaultCopyShortcutKeyCode = Int(kVK_ANSI_C)
  static let defaultPasteShortcutKeyCode = Int(kVK_ANSI_V)
  static let defaultShortcutFlags = CGEventFlags.maskCommand.union(.maskAlternate).rawValue
  static let defaultClearCacheAfterPaste = false
  static let defaultClearCacheOnSleep = false
  static let defaultPasteTypingInterval: TimeInterval = 0.01
}

struct EnkoConfig {
  static let appLanguagesKey = "enko.appLanguages"
  static let copyKeyCodeKey = "enko.copyShortcutKeyCode"
  static let copyFlagsKey = "enko.copyShortcutFlags"
  static let pasteKeyCodeKey = "enko.pasteShortcutKeyCode"
  static let pasteFlagsKey = "enko.pasteShortcutFlags"
  static let clearSecureCacheAfterPasteKey = "enko.clearSecureCacheAfterPaste"
  static let clearSecureCacheOnSleepKey = "enko.clearSecureCacheOnSleep"
  static let pasteTypingIntervalKey = "enko.pasteTypingInterval"

  static var appLanguages: [String] {
    get {
      secureValue(forKey: appLanguagesKey, defaultValue: EnkoDefine.defaultAppLanguages)
    }
    set {
      setSecureValue(newValue, forKey: appLanguagesKey)
    }
  }

  static var copyShortcutKeyCode: CGKeyCode {
    get {
      let value: Int = secureValue(forKey: copyKeyCodeKey, defaultValue: EnkoDefine.defaultCopyShortcutKeyCode)
      return CGKeyCode(value)
    }
    set {
      setSecureValue(Int(newValue), forKey: copyKeyCodeKey)
    }
  }

  static var copyShortcutFlags: CGEventFlags {
    get {
      let value: UInt64 = secureValue(forKey: copyFlagsKey, defaultValue: EnkoDefine.defaultShortcutFlags)
      return CGEventFlags(rawValue: value)
    }
    set {
      setSecureValue(newValue.rawValue, forKey: copyFlagsKey)
    }
  }

  static var pasteShortcutKeyCode: CGKeyCode {
    get {
      let value: Int = secureValue(forKey: pasteKeyCodeKey, defaultValue: EnkoDefine.defaultPasteShortcutKeyCode)
      return CGKeyCode(value)
    }
    set {
      setSecureValue(Int(newValue), forKey: pasteKeyCodeKey)
    }
  }

  static var pasteShortcutFlags: CGEventFlags {
    get {
      let value: UInt64 = secureValue(forKey: pasteFlagsKey, defaultValue: EnkoDefine.defaultShortcutFlags)
      return CGEventFlags(rawValue: value)
    }
    set {
      setSecureValue(newValue.rawValue, forKey: pasteFlagsKey)
    }
  }

  static var clearSecureCacheAfterPaste: Bool {
    get {
      secureValue(forKey: clearSecureCacheAfterPasteKey, defaultValue: EnkoDefine.defaultClearCacheAfterPaste)
    }
    set {
      setSecureValue(newValue, forKey: clearSecureCacheAfterPasteKey)
    }
  }

  static var clearSecureCacheOnSleep: Bool {
    get {
      secureValue(forKey: clearSecureCacheOnSleepKey, defaultValue: EnkoDefine.defaultClearCacheOnSleep)
    }
    set {
      setSecureValue(newValue, forKey: clearSecureCacheOnSleepKey)
    }
  }

  static var pasteTypingInterval: TimeInterval {
    get {
      let value: Double = secureValue(forKey: pasteTypingIntervalKey, defaultValue: EnkoDefine.defaultPasteTypingInterval)
      return clampPasteTypingInterval(value)
    }
    set {
      setSecureValue(clampPasteTypingInterval(newValue), forKey: pasteTypingIntervalKey)
    }
  }

  static func clampPasteTypingInterval(_ value: TimeInterval) -> TimeInterval {
    min(max(value, 0.001), 0.100)
  }

  static func normalizeFlags(_ flags: CGEventFlags) -> CGEventFlags {
    let raw = flags.intersection([.maskCommand, .maskControl, .maskAlternate, .maskShift]).rawValue
    return CGEventFlags(rawValue: raw)
  }

  private static func secureValue<T: Codable>(forKey key: String, defaultValue: T) -> T {
    if let value: T = EnkoSecureConfigStore.read(key: key) {
      return value
    }
    return defaultValue
  }

  private static func setSecureValue<T: Codable>(_ value: T, forKey key: String) {
    _ = EnkoSecureConfigStore.write(value, key: key)
  }
}

enum EnkoKeychainRootKey {
  private static let service = "xingroam.Enko"
  private static let account = "enko.keychain.root.v1"

  static func encrypt(data: Data, context: String) -> Data? {
    guard let rootKey = rootKey(),
          let sealed = try? AES.GCM.seal(data, using: rootKey, authenticating: Data(context.utf8)).combined else {
      return nil
    }
    return sealed
  }

  static func decrypt(data: Data, context: String) -> Data? {
    guard let rootKey = rootKey(),
          let box = try? AES.GCM.SealedBox(combined: data),
          let plain = try? AES.GCM.open(box, using: rootKey, authenticating: Data(context.utf8)) else {
      return nil
    }
    return plain
  }

  private static func rootKey() -> SymmetricKey? {
    if let keyData = readKeyData() {
      return SymmetricKey(data: keyData)
    }

    var newKeyData = Data((0..<32).map { _ in UInt8.random(in: .min ... .max) })
    defer {
      if !newKeyData.isEmpty {
        newKeyData.resetBytes(in: 0..<newKeyData.count)
      }
    }

    guard storeKeyData(newKeyData), let stored = readKeyData() else {
      return nil
    }
    return SymmetricKey(data: stored)
  }

  private static func readKeyData() -> Data? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]

    var result: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    guard status == errSecSuccess else { return nil }
    return result as? Data
  }

  private static func storeKeyData(_ keyData: Data) -> Bool {
    let attrs: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
      kSecValueData as String: keyData
    ]

    let status = SecItemAdd(attrs as CFDictionary, nil)
    return status == errSecSuccess || status == errSecDuplicateItem
  }
}

private enum EnkoSecureConfigStore {
  private static let prefix = "enko.secure.v1."

  static func write<T: Codable>(_ value: T, key: String) -> Bool {
    guard let plainData = try? JSONEncoder().encode(value),
          let encrypted = EnkoKeychainRootKey.encrypt(data: plainData, context: key) else {
      return false
    }
    UserDefaults.standard.set(encrypted.base64EncodedString(), forKey: secureStorageKey(for: key))
    return true
  }

  static func read<T: Codable>(key: String) -> T? {
    guard let encoded = UserDefaults.standard.string(forKey: secureStorageKey(for: key)),
          let encrypted = Data(base64Encoded: encoded),
          let plainData = EnkoKeychainRootKey.decrypt(data: encrypted, context: key),
          let value = try? JSONDecoder().decode(T.self, from: plainData) else {
      return nil
    }
    return value
  }

  private static func secureStorageKey(for key: String) -> String {
    prefix + key
  }
}