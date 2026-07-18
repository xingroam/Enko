import SwiftUI
import AppKit

@main
struct App: SwiftUI.App {
  @NSApplicationDelegateAdaptor(AppDel.self) var del
  @StateObject private var statusBarState = EnkoStatusBarState.s

  private func statusBarIconImage(named name: String) -> NSImage {
    let targetSize = NSSize(width: 18, height: 18)
    guard let image = NSImage(named: name) else {
      return NSImage(size: targetSize)
    }
    let resizedImage = NSImage(size: targetSize)
    resizedImage.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    image.draw(in: NSRect(origin: .zero, size: targetSize), from: .zero, operation: .copy, fraction: 1.0)
    resizedImage.unlockFocus()
    resizedImage.isTemplate = true
    return resizedImage
  }

  var body: some Scene {
    MenuBarExtra {
      StatusBarMenuWindowContentView()
    } label: {
      StatusBarAnimatedIconView(
        normalImage: statusBarIconImage(named: "StatusBarIcon"),
        copyImage: statusBarIconImage(named: "StatusBarIconShield"),
        feedbackToken: statusBarState.copyFeedbackToken
      )
    }
    .menuBarExtraStyle(.window)
    .windowResizability(.contentSize)

    Settings {
      EmptyView()
    }
  }
}

private struct StatusBarAnimatedIconView: View {
  let normalImage: NSImage
  let copyImage: NSImage
  let feedbackToken: Int

  @State private var animationToken: Int = 0
  @State private var showingCopyIcon: Bool = false

  var body: some View {
    Image(nsImage: showingCopyIcon ? copyImage : normalImage)
      .renderingMode(.template)
      .resizable()
      .aspectRatio(contentMode: .fit)
      .frame(width: 18, height: 18)
    .onChange(of: feedbackToken) { _, _ in
      playCopyAnimation()
    }
  }

  private func playCopyAnimation() {
    animationToken &+= 1
    let currentToken = animationToken

    showingCopyIcon = true

    DispatchQueue.main.asyncAfter(deadline: .now() + EnkoInfo.statusBarCopyAnimationDuration) {
      guard currentToken == animationToken else { return }
      showingCopyIcon = false
    }
  }
}

class AppDel: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    Enko.s.boot()
  }

  func applicationWillTerminate(_ notification: Notification) {
    Enko.s.end()
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    false
  }
}
