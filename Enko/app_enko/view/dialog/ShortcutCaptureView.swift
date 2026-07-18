import SwiftUI
import AppKit
import ApplicationServices

struct ShortcutCaptureView: View {
  let title: String
  let initialKeyCode: CGKeyCode?
  let initialFlags: CGEventFlags
  let onSave: (CGKeyCode?, CGEventFlags) -> Void
  let onCancel: () -> Void

  @StateObject private var languageManager = LanguageManager.s
  @State private var currentKeyCode: CGKeyCode?
  @State private var currentFlags: CGEventFlags = .disabled
  @State private var isRecording = false
  @State private var eventMonitor: Any?

  private var hasChanges: Bool {
    currentKeyCode != initialKeyCode || currentFlags != initialFlags
  }

  private var shortcutDisplayText: String {
    if isRecording {
      return languageManager.localizedString("system.shortcut.dialog.recording")
    }
    if let currentKeyCode {
      return Keyboard.fullNameShortcut(keyCode: currentKeyCode, flags: currentFlags)
    }
    return languageManager.localizedString("system.shortcut.dialog.click_to_set")
  }

  var body: some View {
    VStack(spacing: 18) {
      Text(title)
        .font(.system(size: 18, weight: .semibold))

      Button {
        if isRecording {
          stopRecording()
        } else {
          startRecording()
        }
      } label: {
        Text(shortcutDisplayText)
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 10)
          .background(isRecording ? Color.orange : Color.accentColor)
          .clipShape(Capsule(style: .continuous))
      }
      .buttonStyle(.plain)

      HStack(spacing: 10) {
        Button(languageManager.localizedString("enko.common.clear")) {
          stopRecording()
          currentKeyCode = nil
          currentFlags = .disabled
        }
        .buttonStyle(.bordered)
        .disabled(currentKeyCode == nil)

        Spacer(minLength: 0)

        Button(languageManager.localizedString("enko.common.cancel")) {
          stopRecording()
          onCancel()
        }
        .buttonStyle(.bordered)

        Button(languageManager.localizedString("enko.common.save")) {
          stopRecording()
          onSave(currentKeyCode, currentFlags)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!hasChanges)
      }
    }
    .padding(20)
    .frame(width: 400)
    .background(.regularMaterial)
    .onAppear {
      currentKeyCode = initialKeyCode
      currentFlags = initialFlags
    }
    .onDisappear {
      stopRecording()
    }
    .onReceive(NotificationCenter.default.publisher(for: NSApplication.willResignActiveNotification)) { _ in
      stopRecording()
    }
  }

  private func startRecording() {
    stopRecording()
    isRecording = true
    eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
      if event.keyCode == 53 {
        stopRecording()
        return nil
      }

      let flags = EnkoConfig.normalizeFlags(CGEventFlags(rawValue: UInt64(event.modifierFlags.rawValue)))
      if flags.isEmpty {
        return nil
      }

      currentKeyCode = event.keyCode
      currentFlags = flags
      stopRecording()
      return nil
    }
  }

  private func stopRecording() {
    isRecording = false
    if let eventMonitor {
      NSEvent.removeMonitor(eventMonitor)
      self.eventMonitor = nil
    }
  }
}
