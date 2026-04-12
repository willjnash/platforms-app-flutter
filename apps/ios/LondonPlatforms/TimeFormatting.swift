import Foundation

enum TimeFormatting {
  /// RTT `HHmm` (or similar) → `HH:mm` for display.
  static func displayHHmm(_ raw: String?) -> String {
    guard let raw, raw.count >= 4 else { return raw ?? "—" }
    let start = raw.startIndex
    let hEnd = raw.index(start, offsetBy: 2)
    let mEnd = raw.index(start, offsetBy: 4)
    return "\(raw[start..<hEnd]):\(raw[hEnd..<mEnd])"
  }

  /// ISO 8601 datetime string → `HHmm`.
  ///
  /// The RTT API v2 returns schedule times without a timezone suffix
  /// (e.g. `"2026-04-12T13:52:00"`), already expressed in UK local time.
  /// We extract HH and MM directly from the string rather than round-tripping
  /// through a Date, which avoids `ISO8601DateFormatter` rejecting the missing
  /// timezone and returning nil for every time field.
  static func hhmmFromISO(_ iso: String?) -> String? {
    guard let iso, iso.count >= 16 else { return nil }
    guard iso[iso.index(iso.startIndex, offsetBy: 10)] == "T" else { return nil }
    let hh = iso[iso.index(iso.startIndex, offsetBy: 11)..<iso.index(iso.startIndex, offsetBy: 13)]
    let mm = iso[iso.index(iso.startIndex, offsetBy: 14)..<iso.index(iso.startIndex, offsetBy: 16)]
    return "\(hh)\(mm)"
  }

  /// `yyyy-MM-dd` runDate → `/yyyy/MM/dd` path segment (kept for compatibility).
  static func serviceDatePathSegment(_ runDate: String) -> String {
    guard runDate.count >= 10 else { return "" }
    let y = runDate.prefix(4)
    let m = runDate.dropFirst(5).prefix(2)
    let d = runDate.dropFirst(8).prefix(2)
    return "/\(y)/\(m)/\(d)"
  }
}
