import Foundation

enum TimeUtils {
  /// Parses `HHmm` into minutes since midnight.
  static func minutesSinceMidnight(_ hhmm: String?) -> Int? {
    guard let hhmm, hhmm.count >= 4 else { return nil }
    let h = Int(hhmm.prefix(2))
    let m = Int(hhmm.dropFirst(2).prefix(2))
    guard let h, let m else { return nil }
    return (h * 60) + m
  }

  /// Difference in minutes from booked to realtime (`realtime - booked`).
  static func delayMinutes(bookedHHmm: String?, realtimeHHmm: String?) -> Int? {
    guard let b = minutesSinceMidnight(bookedHHmm),
          let r = minutesSinceMidnight(realtimeHHmm) else { return nil }
    return r - b
  }
}

