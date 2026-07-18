import ApplicationServices

extension CGKeyCode {
  static let disabled: CGKeyCode = 0xFFFF

  var isDisabled: Bool {
    self == 0xFFFF
  }
}
