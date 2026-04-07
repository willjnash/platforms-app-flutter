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

  /// Best-effort polling interval for glance surfaces, based on minutes until booked departure.
  static func nextCheckIntervalSeconds(bookedHHmm: String?, now: Date = Date()) -> TimeInterval {
    guard let bookedHHmm,
          let minsBooked = minutesSinceMidnight(bookedHHmm)
    else { return 5 * 60 }

    let cal = Calendar.current
    let comps = cal.dateComponents([.hour, .minute], from: now)
    let minsNow = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    let delta = minsBooked - minsNow

    switch delta {
    case let x where x <= 5:
      return 60
    case 6...20:
      return 2 * 60
    case 21...60:
      return 5 * 60
    default:
      return 15 * 60
    }
  }
}

