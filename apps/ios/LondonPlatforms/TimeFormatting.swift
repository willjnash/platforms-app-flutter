import Foundation

enum TimeFormatting {
  /// RTT `HHmm` (or similar) → `HH:mm` for display (SERVICE_SPEC §4.3).
  static func displayHHmm(_ raw: String?) -> String {
    guard let raw, raw.count >= 4 else { return raw ?? "—" }
    let start = raw.startIndex
    let hEnd = raw.index(start, offsetBy: 2)
    let mEnd = raw.index(start, offsetBy: 4)
    return "\(raw[start..<hEnd]):\(raw[hEnd..<mEnd])"
  }

  /// `yyyy-MM-dd` runDate → `/yyyy/MM/dd` path segment (SERVICE_SPEC §3.4).
  static func serviceDatePathSegment(_ runDate: String) -> String {
    guard runDate.count >= 10 else { return "" }
    let y = runDate.prefix(4)
    let m = runDate.dropFirst(5).prefix(2)
    let d = runDate.dropFirst(8).prefix(2)
    return "/\(y)/\(m)/\(d)"
  }
}
