import AppKit

extension ClipboardManager {
  func clonePasteboardItem(_ item: NSPasteboardItem) -> NSPasteboardItem {
    let copy = NSPasteboardItem()
    for type in item.types {
      if let data = item.data(forType: type) {
        copy.setData(data, forType: type)
      } else if let string = item.string(forType: type) {
        copy.setString(string, forType: type)
      }
    }
    return copy
  }
}
