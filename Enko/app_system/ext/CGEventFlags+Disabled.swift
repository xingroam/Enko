import ApplicationServices

extension CGEventFlags {
  static let disabled: CGEventFlags = CGEventFlags(rawValue: 0)

  var isDisabled: Bool {
    self.rawValue == 0
  }
}
