import Foundation
import ServiceManagement

class StartupManager {
  static let s = StartupManager()

  private init() {}

  func isAppInStartupItems() -> Bool {
    SMAppService.mainApp.status == .enabled
  }

  func addAppToStartupItems() {
    do {
      try SMAppService.mainApp.register()
    } catch {
      print("Failed to add to startup items: \(error)")
    }
  }

  func removeAppFromStartupItems() {
    do {
      try SMAppService.mainApp.unregister()
    } catch {
      print("Failed to remove from startup items: \(error)")
    }
  }
}
