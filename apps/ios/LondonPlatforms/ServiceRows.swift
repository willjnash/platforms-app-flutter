import SwiftUI

/// List row layouts for the main board.
enum ServiceRows {}

// MARK: - Departure row

extension ServiceRows {
  struct Departure: View {
    let item: ServiceSummary
    let locationDetail: LocationDetail

    private var isPassThrough: Bool {
      locationDetail.gbttBookedDeparture == nil && locationDetail.passHHmm != nil
    }

    private var scheduledTime: String {
      TimeFormatting.displayHHmm(locationDetail.gbttBookedDeparture ?? locationDetail.passHHmm)
    }

    private var expectedTime: String? {
      guard !isPassThrough,
            let rt = locationDetail.realtimeDeparture,
            rt != locationDetail.gbttBookedDeparture else { return nil }
      return TimeFormatting.displayHHmm(rt)
    }

    private var destination: String {
      locationDetail.destination?.first?.description ?? L10n.emDash
    }

    private var confirmed: Bool { locationDetail.platformConfirmed == true }
    private var changed: Bool { locationDetail.platformChanged == true }
    private var isCancelled: Bool { locationDetail.displayAs == "CANCELLED" }
    private var minutesToDeparture: Int? {
      TimeUtils.minutesUntil(targetHHmm: locationDetail.gbttBookedDeparture)
    }

    private var delayMinutes: Int? {
      if let server = locationDetail.departureLatenessMinutes { return server }
      return TimeUtils.delayMinutes(
        bookedHHmm: locationDetail.gbttBookedDeparture,
        realtimeHHmm: locationDetail.realtimeDeparture
      )
    }

    private var status: ServiceStatus {
      if isCancelled { return .cancelled }
      if isPassThrough { return .passThrough }
      if let delay = delayMinutes, delay > 0 { return .delayed(delay) }
      if locationDetail.realtimeActivated == true { return .onTime }
      return .scheduled
    }

    private var platformConfidence: PlatformConfidence {
      if isCancelled || isPassThrough { return .none }
      if changed { return .changed }
      if confirmed { return .confirmed }
      if let p = locationDetail.platform, !p.isEmpty {
        if let mins = minutesToDeparture, mins <= 10 {
          return .pending
        }
        return .expected
      }
      return .unavailable
    }

    var body: some View {
      HStack(spacing: 12) {
        // Time column
        VStack(alignment: .leading, spacing: 2) {
          Text(scheduledTime)
            .font(.body.monospacedDigit())
            .fontWeight(.medium)
            .foregroundStyle(isCancelled ? .tertiary : .primary)
            .strikethrough(isCancelled)

          if let exp = expectedTime, !isCancelled {
            Text(exp)
              .font(.caption.monospacedDigit().weight(.semibold))
              .foregroundStyle(.orange)
          }
        }
        .frame(minWidth: 52, alignment: .leading)
        .accessibilitySortPriority(0.5)

        // Destination + sub-info
        VStack(alignment: .leading, spacing: 3) {
          // Line 1: destination
          Text(destination)
            .font(.body)
            .fontWeight(confirmed ? .semibold : .regular)
            .foregroundStyle(isCancelled ? .secondary : .primary)
            .strikethrough(isCancelled)

          // Line 2: headcode · operator · coaches — all caption, one line
          subInfoLine

          // Line 3: status badges — only when something noteworthy to show
          let hasLine3 = status != .onTime && status != .scheduled
            || locationDetail.departureStatus != nil
            || isBusReplacement
            || platformConfidence.chip != nil
          if hasLine3 {
            HStack(spacing: 4) {
              StatusBadge(status: status)
              LiveStatusChip(liveStatus: locationDetail.departureStatus)
              if isBusReplacement {
                CapsuleBadge(text: L10n.busReplacementBadge, style: .purple)
              }
              if let chip = platformConfidence.chip {
                CapsuleBadge(
                  text: chip.text,
                  style: chip.style,
                  foregroundOverride: chip.usesPrimaryText ? Color.primary : nil
                )
                  .accessibilityLabel(chip.accessibilityLabel)
              }
            }
          }

          if let reason = locationDetail.delayReason, (isCancelled || status.isDelayed) {
            Text(reason)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        // Trailing: platform only
        PlatformBadge(
          platform: locationDetail.platform,
          isConfirmed: confirmed,
          isCancelled: isCancelled || isPassThrough
        )
      }
      .padding(.vertical, 2)
      .accessibilityElement(children: .combine)
      .accessibilityLabel(accessibilitySummary)
    }

    private var subInfoLine: some View {
      var parts: [String] = []
      if let headcode = item.trainIdentity { parts.append(headcode) }
      if let op = item.atocName, !op.isEmpty { parts.append(op) }
      if let n = locationDetail.numberOfVehicles, n > 0, !isCancelled {
        parts.append(L10n.vehiclesFormat(n))
      }
      return Text(parts.joined(separator: " · "))
        .font(.caption.monospacedDigit())
        .foregroundStyle(.secondary)
        .lineLimit(2)
    }

    private var isBusReplacement: Bool {
      guard let mode = item.modeType else { return false }
      return mode == "REPLACEMENT_BUS" || mode == "BUS" || mode == "SCHEDULED_BUS"
    }

    private var accessibilitySummary: String {
      var parts = [scheduledTime, destination, item.atocName ?? ""]
      switch status {
      case .onTime: parts.append(L10n.statusOnTime)
      case .delayed(let m): parts.append(L10n.delayA11y(m))
      case .cancelled: parts.append(L10n.statusCancelled)
      case .passThrough: parts.append(L10n.statusPassThrough)
      case .scheduled: break
      }
      if confirmed, let p = locationDetail.platform, !p.isEmpty {
        parts.append(L10n.platformConfirmedA11y(p))
      } else {
        parts.append(platformConfidence.accessibilityLabel)
      }
      return parts.joined(separator: ". ")
    }
  }
}

// MARK: - Arrival row

extension ServiceRows {
  struct Arrival: View {
    let item: ServiceSummary
    let locationDetail: LocationDetail

    private var origin: String {
      locationDetail.origin?.first?.description ?? L10n.emDash
    }

    private var scheduledTime: String {
      TimeFormatting.displayHHmm(locationDetail.destination?.first?.publicTime)
    }

    private var expectedTime: String? {
      guard let rt = locationDetail.realtimeArrival,
            let booked = locationDetail.gbttBookedArrival,
            rt != booked else { return nil }
      return TimeFormatting.displayHHmm(rt)
    }

    private var isCancelled: Bool { locationDetail.displayAs == "CANCELLED" }

    private var delayMinutes: Int? {
      if let server = locationDetail.arrivalLatenessMinutes { return server }
      return TimeUtils.delayMinutes(
        bookedHHmm: locationDetail.gbttBookedArrival,
        realtimeHHmm: locationDetail.realtimeArrival
      )
    }

    private var status: ServiceStatus {
      if isCancelled { return .cancelled }
      if let delay = delayMinutes, delay > 0 { return .delayed(delay) }
      if locationDetail.realtimeActivated == true { return .onTime }
      return .scheduled
    }

    var body: some View {
      HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 2) {
          Text(scheduledTime)
            .font(.body.monospacedDigit())
            .fontWeight(.medium)
            .foregroundStyle(isCancelled ? .tertiary : .primary)
            .strikethrough(isCancelled)

          if let exp = expectedTime, !isCancelled {
            Text(exp)
              .font(.caption.monospacedDigit().weight(.semibold))
              .foregroundStyle(.orange)
          }
        }
        .frame(minWidth: 52, alignment: .leading)

        VStack(alignment: .leading, spacing: 3) {
          // Line 1: origin
          Text(origin)
            .font(.body)
            .fontWeight(.semibold)
            .foregroundStyle(isCancelled ? .secondary : .primary)
            .strikethrough(isCancelled)

          // Line 2: headcode · operator · coaches
          subInfoLine

          // Line 3: status badges — only when noteworthy
          let hasLine3 = status != .onTime && status != .scheduled
            || locationDetail.arrivalStatus != nil
          if hasLine3 {
            HStack(spacing: 4) {
              StatusBadge(status: status)
              LiveStatusChip(liveStatus: locationDetail.arrivalStatus)
            }
          }

          if let reason = locationDetail.delayReason, (isCancelled || status.isDelayed) {
            Text(reason)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        // Trailing: platform only
        PlatformBadge(
          platform: locationDetail.platform,
          isConfirmed: false,
          isCancelled: isCancelled
        )
      }
      .padding(.vertical, 2)
      .accessibilityElement(children: .combine)
      .accessibilityLabel(accessibilitySummary)
    }

    private var subInfoLine: some View {
      var parts: [String] = []
      if let headcode = item.trainIdentity { parts.append(headcode) }
      if let op = item.atocName, !op.isEmpty { parts.append(op) }
      if let n = locationDetail.numberOfVehicles, n > 0, !isCancelled {
        parts.append(L10n.vehiclesFormat(n))
      }
      return Text(parts.joined(separator: " · "))
        .font(.caption.monospacedDigit())
        .foregroundStyle(.secondary)
        .lineLimit(2)
    }

    private var accessibilitySummary: String {
      var parts = [scheduledTime, origin, item.atocName ?? ""]
      switch status {
      case .onTime: parts.append(L10n.statusOnTime)
      case .delayed(let m): parts.append(L10n.delayA11y(m))
      case .cancelled: parts.append(L10n.statusCancelled)
      case .passThrough, .scheduled: break
      }
      if let p = locationDetail.platform, !p.isEmpty {
        parts.append(L10n.arrivalRowA11y(time: scheduledTime, origin: origin, operatorName: "", platform: p))
      }
      return parts.joined(separator: ". ")
    }
  }
}

// MARK: - Service status

enum ServiceStatus: Equatable {
  case scheduled
  case onTime
  case delayed(Int)
  case cancelled
  case passThrough

  var isDelayed: Bool {
    if case .delayed = self { return true }
    return false
  }
}

private enum PlatformConfidence {
  case none
  case changed
  case confirmed
  case expected
  case pending
  case unavailable

  struct Chip {
    let text: String
    let style: CapsuleBadge.BadgeStyle
    let accessibilityLabel: String
    let usesPrimaryText: Bool
  }

  var accessibilityLabel: String {
    switch self {
    case .none:
      return ""
    case .changed:
      return L10n.platformChangedA11y
    case .confirmed:
      return L10n.platformConfidenceConfirmed
    case .expected:
      return L10n.platformConfidenceExpected
    case .pending:
      return L10n.platformConfidencePending
    case .unavailable:
      return L10n.platformConfidenceUnavailable
    }
  }

  var chip: Chip? {
    switch self {
    case .none:
      return nil
    case .changed:
      return Chip(
        text: L10n.platformConfidenceChanged,
        style: .orange,
        accessibilityLabel: L10n.platformChangedA11y,
        usesPrimaryText: true
      )
    case .confirmed:
      return Chip(
        text: L10n.platformConfidenceConfirmed,
        style: .green,
        accessibilityLabel: L10n.platformConfidenceConfirmed,
        usesPrimaryText: true
      )
    case .expected:
      return Chip(
        text: L10n.platformConfidenceExpected,
        style: .secondary,
        accessibilityLabel: L10n.platformConfidenceExpected,
        usesPrimaryText: false
      )
    case .pending:
      return Chip(
        text: L10n.platformConfidencePending,
        style: .yellow,
        accessibilityLabel: L10n.platformConfidencePending,
        usesPrimaryText: false
      )
    case .unavailable:
      return Chip(
        text: L10n.platformConfidenceUnavailable,
        style: .secondary,
        accessibilityLabel: L10n.platformConfidenceUnavailable,
        usesPrimaryText: false
      )
    }
  }
}

// MARK: - Status badge

private struct StatusBadge: View {
  let status: ServiceStatus

  var body: some View {
    switch status {
    case .scheduled, .onTime:
      EmptyView()
    case .delayed(let minutes):
      CapsuleBadge(text: L10n.statusDelayed(minutes), style: .orange)
    case .cancelled:
      CapsuleBadge(text: L10n.statusCancelled, style: .red)
    case .passThrough:
      CapsuleBadge(text: L10n.statusPassThrough, style: .secondary)
    }
  }
}

// MARK: - Live status chip

/// Shows the real-time operational status of the train at this location
/// (e.g. "Approaching", "At platform", "Departing").
struct LiveStatusChip: View {
  let liveStatus: String?

  var body: some View {
    guard let liveStatus else { return AnyView(EmptyView()) }
    switch liveStatus {
    case "APPROACHING":
      return AnyView(CapsuleBadge(text: L10n.statusApproaching, style: .yellow))
    case "ARRIVING":
      return AnyView(CapsuleBadge(text: L10n.statusArriving, style: .green))
    case "AT_PLATFORM":
      return AnyView(CapsuleBadge(text: L10n.statusAtPlatform, style: .green))
    case "DEPARTING":
      return AnyView(CapsuleBadge(text: L10n.statusDeparting, style: .blue))
    case "DEPART_PREPARING":
      return AnyView(CapsuleBadge(text: L10n.statusDepartPreparing, style: .blue))
    case "DEPART_READY":
      return AnyView(CapsuleBadge(text: L10n.statusDepartReady, style: .green))
    default:
      return AnyView(EmptyView())
    }
  }
}

// MARK: - Capsule badge (reusable)

struct CapsuleBadge: View {
  let text: String
  let style: BadgeStyle
  let foregroundOverride: Color?

  init(text: String, style: BadgeStyle, foregroundOverride: Color? = nil) {
    self.text = text
    self.style = style
    self.foregroundOverride = foregroundOverride
  }

  enum BadgeStyle {
    case green, orange, red, yellow, blue, purple, secondary

    var foreground: Color {
      switch self {
      case .green: .green
      case .orange: .orange
      case .red: .red
      case .yellow: .primary
      case .blue: .blue
      case .purple: .purple
      case .secondary: .secondary
      }
    }

    var background: Color {
      switch self {
      case .green: Color.green.opacity(0.12)
      case .orange: Color.orange.opacity(0.12)
      case .red: Color.red.opacity(0.12)
      case .yellow: Color.yellow.opacity(0.28)
      case .blue: Color.blue.opacity(0.12)
      case .purple: Color.purple.opacity(0.12)
      case .secondary: Color.secondary.opacity(0.1)
      }
    }
  }

  var body: some View {
    Text(text)
      .font(.caption2.weight(.semibold))
      .foregroundStyle(foregroundOverride ?? style.foreground)
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .background(style.background, in: Capsule())
  }
}

// MARK: - Platform badge

struct PlatformBadge: View {
  let platform: String?
  let isConfirmed: Bool
  let isCancelled: Bool

  var body: some View {
    if isCancelled {
      EmptyView()
    } else if let p = platform, !p.isEmpty {
      Text(p)
        .font(.headline.monospacedDigit())
        .foregroundStyle(isConfirmed ? .white : .secondary)
        .frame(minWidth: 34, minHeight: 34, maxHeight: 34, alignment: .center)
        .background(
          RoundedRectangle(cornerRadius: 8)
            .fill(isConfirmed ? Color.green : Color.clear)
            .overlay(
              RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isConfirmed ? Color.clear : Color.secondary.opacity(0.3), lineWidth: 1.5)
            )
        )
        .accessibilityLabel(
          isConfirmed ? L10n.platformConfirmedA11y(p) : L10n.platformPendingA11y(p)
        )
    } else {
      Text(L10n.emDash)
        .font(.body)
        .foregroundStyle(.quaternary)
        .frame(minWidth: 34)
    }
  }
}

// MARK: - Confirmed departure row accent

extension View {
  @ViewBuilder
  func confirmedDepartureStyle(isConfirmed: Bool) -> some View {
    if isConfirmed {
      self.listRowBackground(
        HStack(spacing: 0) {
          Rectangle()
            .fill(Color.green)
            .frame(width: 4)
          Color.clear
        }
      )
    } else {
      self
    }
  }
}
