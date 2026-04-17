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

  /// Returns current local minutes since midnight.
  static func currentMinutesSinceMidnight(now: Date = Date(), calendar: Calendar = .current) -> Int? {
    let comps = calendar.dateComponents(in: .current, from: now)
    guard let h = comps.hour, let m = comps.minute else { return nil }
    return (h * 60) + m
  }

  /// Minutes from now until `targetHHmm` on the same local day.
  /// Negative values indicate the time has already passed.
  static func minutesUntil(targetHHmm: String?, now: Date = Date(), calendar: Calendar = .current) -> Int? {
    guard let target = minutesSinceMidnight(targetHHmm),
          let current = currentMinutesSinceMidnight(now: now, calendar: calendar) else { return nil }
    return target - current
  }

  /// Returns a sort key for `hhmm` that handles midnight crossover correctly.
  ///
  /// If the raw `minutesSinceMidnight` value looks more than 12 hours before
  /// `currentMinutes` (i.e., it appears to be yesterday's time), 1440 is added
  /// so that, e.g., `00:05` sorts after `23:55` rather than before it.
  static func minutesSinceMidnightForSorting(_ hhmm: String?, currentMinutes: Int) -> Int {
    guard let raw = minutesSinceMidnight(hhmm) else { return Int.max }
    return raw < currentMinutes - 720 ? raw + 1440 : raw
  }

  /// Returns the `HHmm` string for the local time `minutes` from now.
  /// Pass a negative value (e.g. `-60`) to look into the past.
  static func hhmmOffset(minutes: Int, now: Date = Date(), calendar: Calendar = .current) -> String? {
    guard let adjusted = calendar.date(byAdding: .minute, value: minutes, to: now) else { return nil }
    let comps = calendar.dateComponents(in: .current, from: adjusted)
    guard let h = comps.hour, let m = comps.minute else { return nil }
    return String(format: "%02d%02d", h, m)
  }
}

