import UIKit

enum Feedback {
  /// Light haptic after a user-initiated refresh completes (success or failure).
  static func boardRefreshCompleted(success: Bool) {
    let generator = UINotificationFeedbackGenerator()
    generator.prepare()
    generator.notificationOccurred(success ? .success : .error)
  }
}
