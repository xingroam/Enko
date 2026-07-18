import Foundation
import CryptoKit
import Dispatch

extension ClipboardManager {
  func storeEncryptedText(_ text: String) -> Bool {
    let sessionWrapKey = currentSessionWrapKey()
    let payloadKey = SymmetricKey(size: .bits256)
    guard let plainData = text.data(using: .utf8),
          let encryptedPayload = try? AES.GCM.seal(plainData, using: payloadKey).combined else {
      return false
    }

    var payloadKeyData = Data(payloadKey.withUnsafeBytes { Data($0) })
    guard let encryptedPayloadKey = try? AES.GCM.seal(payloadKeyData, using: sessionWrapKey).combined else {
      payloadKeyData.resetBytes(in: 0..<payloadKeyData.count)
      return false
    }
    payloadKeyData.resetBytes(in: 0..<payloadKeyData.count)

    stateQueue.sync {
      encryptedPayloadData = encryptedPayload
      encryptedPayloadKeyData = encryptedPayloadKey
    }
    return true
  }

  func decryptedText() -> String? {
    let snapshot = encryptedPayloadSnapshot(consume: false)
    guard let snapshot else { return nil }
    return decryptedText(from: snapshot)
  }

  func decryptedText(from snapshot: (encryptedPayload: Data, encryptedPayloadKey: Data)) -> String? {
    let sessionWrapKey = currentSessionWrapKey()
    guard let payloadKeySealedBox = try? AES.GCM.SealedBox(combined: snapshot.encryptedPayloadKey),
          var payloadKeyData = try? AES.GCM.open(payloadKeySealedBox, using: sessionWrapKey),
          let payloadSealedBox = try? AES.GCM.SealedBox(combined: snapshot.encryptedPayload) else {
      return nil
    }
    defer {
      if !payloadKeyData.isEmpty {
        payloadKeyData.resetBytes(in: 0..<payloadKeyData.count)
      }
    }

    let payloadKey = SymmetricKey(data: payloadKeyData)
    guard let plainData = try? AES.GCM.open(payloadSealedBox, using: payloadKey) else {
      return nil
    }
    return String(data: plainData, encoding: .utf8)
  }

  func encryptedPayloadSnapshot(consume: Bool) -> (encryptedPayload: Data, encryptedPayloadKey: Data)? {
    stateQueue.sync {
      guard let encryptedPayloadData,
            let encryptedPayloadKeyData else {
        return nil
      }

      let snapshot = (encryptedPayload: encryptedPayloadData, encryptedPayloadKey: encryptedPayloadKeyData)

      if consume {
        self.encryptedPayloadData = nil
        self.encryptedPayloadKeyData = nil
      }

      return snapshot
    }
  }

  func clearSecureCache() {
    stateQueue.sync {
      encryptedPayloadData = nil
      encryptedPayloadKeyData = nil
    }
    refreshSessionWrapKey()
  }

  func refreshSessionWrapKey() {
    let sessionWrapKey = SymmetricKey(size: .bits256)
    var keyData = Data(sessionWrapKey.withUnsafeBytes { Data($0) })
    defer {
      if !keyData.isEmpty {
        keyData.resetBytes(in: 0..<keyData.count)
      }
    }

    let encrypted = EnkoKeychainRootKey.encrypt(data: keyData, context: "clipboard.session.wrap.key.v1")

    stateQueue.sync {
      if let encrypted {
        encryptedSessionWrapKeyData = encrypted
      } else {
        encryptedSessionWrapKeyData = nil
        fallbackSessionWrapKey = sessionWrapKey
      }
    }
  }

  func currentSessionWrapKey() -> SymmetricKey {
    let snapshot = stateQueue.sync { (encryptedSessionWrapKeyData, fallbackSessionWrapKey) }
    if let encrypted = snapshot.0,
       var keyData = EnkoKeychainRootKey.decrypt(data: encrypted, context: "clipboard.session.wrap.key.v1") {
      defer {
        if !keyData.isEmpty {
          keyData.resetBytes(in: 0..<keyData.count)
        }
      }
      return SymmetricKey(data: keyData)
    }
    return snapshot.1
  }
}
