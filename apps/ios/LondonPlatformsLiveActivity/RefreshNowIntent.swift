import AppIntents
import Foundation

struct RefreshNowIntent: AppIntent {
  static var title: LocalizedStringResource = "Refresh now"
  static var openAppWhenRun: Bool = true

  func perform() async throws -> some IntentResult {
    let url = URL(string: "londonplatforms://refresh")!
    return .result(value: url)
  }
}

