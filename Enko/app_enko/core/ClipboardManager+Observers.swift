import AppKit

extension ClipboardManager {
  func setupAppActiveObserverIfNeeded() {
    guard appActiveObserver == nil else { return }
    appActiveObserver = NotificationCenter.default.addObserver(
      forName: NSApplication.didBecomeActiveNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.start()
    }
  }

  func setupWorkspaceSecurityObserversIfNeeded() {
    let workspaceNotificationCenter = NSWorkspace.shared.notificationCenter

    if workspaceSleepObserver == nil {
      workspaceSleepObserver = workspaceNotificationCenter.addObserver(
        forName: NSWorkspace.willSleepNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        guard EnkoConfig.clearSecureCacheOnSleep else { return }
        self?.clearSecureCache()
      }
    }

    if workspaceSessionResignObserver == nil {
      workspaceSessionResignObserver = workspaceNotificationCenter.addObserver(
        forName: NSWorkspace.sessionDidResignActiveNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        guard EnkoConfig.clearSecureCacheOnSleep else { return }
        self?.clearSecureCache()
      }
    }

    if screenLockObserver == nil {
      screenLockObserver = DistributedNotificationCenter.default().addObserver(
        forName: Notification.Name("com.apple.screenIsLocked"),
        object: nil,
        queue: .main
      ) { [weak self] _ in
        guard EnkoConfig.clearSecureCacheOnSleep else { return }
        self?.clearSecureCache()
      }
    }
  }

  func teardownObservers() {
    if let appActiveObserver {
      NotificationCenter.default.removeObserver(appActiveObserver)
      self.appActiveObserver = nil
    }

    let workspaceNotificationCenter = NSWorkspace.shared.notificationCenter
    if let workspaceSleepObserver {
      workspaceNotificationCenter.removeObserver(workspaceSleepObserver)
      self.workspaceSleepObserver = nil
    }
    if let workspaceSessionResignObserver {
      workspaceNotificationCenter.removeObserver(workspaceSessionResignObserver)
      self.workspaceSessionResignObserver = nil
    }

    if let screenLockObserver {
      DistributedNotificationCenter.default().removeObserver(screenLockObserver)
      self.screenLockObserver = nil
    }
  }
}
