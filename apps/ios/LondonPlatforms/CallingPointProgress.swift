import Foundation

/// Where the train is along the visible calling-point list (same order as API).
enum CallingPointProgress: Equatable, Sendable {
  case passed
  case current
  case next
  case upcoming

  /// One progress value per entry in `locations` (already filtered to visible calling points).
  static func values(for locations: [ServiceLocation], now: Date = Date()) -> [CallingPointProgress] {
    let n = locations.count
    guard n > 0 else { return [] }

    if locations.allSatisfy({ $0.isCancelledCallingPoint }) {
      return Array(repeating: .upcoming, count: n)
    }

    if let idx = locations.firstIndex(where: { hasActiveRealtimeStatus($0) && !$0.isCancelledCallingPoint }) {
      return (0..<n).map { j in
        let loc = locations[j]
        if loc.isCancelledCallingPoint { return .upcoming }
        if j < idx { return .passed }
        if j == idx { return .current }
        return .upcoming
      }
    }

    if let idx = locations.firstIndex(where: { timeAtStop($0, now: now) && !$0.isCancelledCallingPoint }) {
      return (0..<n).map { j in
        let loc = locations[j]
        if loc.isCancelledCallingPoint { return .upcoming }
        if j < idx { return .passed }
        if j == idx { return .current }
        return .upcoming
      }
    }

    if let lastDeparted = locations.lastIndex(where: { $0.realtimeDepartureActual && !$0.isCancelledCallingPoint }) {
      let nextIdx = lastDeparted + 1
      return (0..<n).map { j in
        let loc = locations[j]
        if loc.isCancelledCallingPoint { return .upcoming }
        if j <= lastDeparted { return .passed }
        if j == nextIdx && nextIdx < n { return .next }
        return .upcoming
      }
    }

    guard let nowM = TimeUtils.currentMinutesSinceMidnight(now: now) else {
      return Array(repeating: .upcoming, count: n)
    }

    if let nextIdx = locations.firstIndex(where: { loc in
      guard !loc.isCancelledCallingPoint, let arr = effectiveArrivalMinutes(loc) else { return false }
      return nowM < arr
    }) {
      return (0..<n).map { j in
        let loc = locations[j]
        if loc.isCancelledCallingPoint { return .upcoming }
        if j < nextIdx { return .passed }
        if j == nextIdx { return .next }
        return .upcoming
      }
    }

    return (0..<n).map { j in
      locations[j].isCancelledCallingPoint ? .upcoming : .passed
    }
  }

  /// Extra VoiceOver phrase for this row’s progress (nil for `.upcoming`).
  static func accessibilityPhrase(for progress: CallingPointProgress) -> String? {
    switch progress {
    case .passed:
      return L10n.callingPointProgressPassedA11y
    case .current:
      return L10n.callingPointProgressCurrentA11y
    case .next:
      return L10n.callingPointProgressNextA11y
    case .upcoming:
      return nil
    }
  }

  // MARK: - Private

  private static let arrivalActiveStatuses: Set<String> = [
    "APPROACHING", "ARRIVING", "AT_PLATFORM",
  ]

  private static let departureActiveStatuses: Set<String> = [
    "AT_PLATFORM", "DEPART_PREPARING", "DEPART_READY", "DEPARTING",
  ]

  private static func hasActiveRealtimeStatus(_ loc: ServiceLocation) -> Bool {
    if let d = loc.departureStatus, departureActiveStatuses.contains(d) { return true }
    if let a = loc.arrivalStatus, arrivalActiveStatuses.contains(a) { return true }
    return false
  }

  private static func effectiveArrivalMinutes(_ loc: ServiceLocation) -> Int? {
    TimeUtils.minutesSinceMidnight(loc.realtimeArrival ?? loc.gbttBookedArrival)
  }

  private static func effectiveDepartureMinutes(_ loc: ServiceLocation) -> Int? {
    if let d = TimeUtils.minutesSinceMidnight(loc.realtimeDeparture ?? loc.gbttBookedDeparture) {
      return d
    }
    return effectiveArrivalMinutes(loc)
  }

  private static func timeAtStop(_ loc: ServiceLocation, now: Date) -> Bool {
    guard !loc.isCancelledCallingPoint,
          let nowM = TimeUtils.currentMinutesSinceMidnight(now: now),
          let arrM = effectiveArrivalMinutes(loc) else { return false }
    let depM = effectiveDepartureMinutes(loc) ?? arrM
    return nowM >= arrM && nowM <= depM
  }
}

private extension ServiceLocation {
  var isCancelledCallingPoint: Bool {
    displayAs == "CANCELLED"
  }
}
