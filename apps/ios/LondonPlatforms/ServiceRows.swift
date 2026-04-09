import SwiftUI

/// List row layouts for the main board.
enum ServiceRows {}

// MARK: - Departure row

extension ServiceRows {
  struct Departure: View {
    let item: ServiceSummary
    let locationDetail: LocationDetail

    private var destination: String {
      locationDetail.destination?.first?.description ?? L10n.emDash
    }

    private var scheduledTime: String {
      TimeFormatting.displayHHmm(locationDetail.gbttBookedDeparture)
    }

    private var expectedTime: String? {
      guard let rt = locationDetail.realtimeDeparture,
            rt != locationDetail.gbttBookedDeparture else { return nil }
      return TimeFormatting.displayHHmm(rt)
    }

    private var confirmed: Bool { locationDetail.platformConfirmed == true }
    private var changed: Bool { locationDetail.platformChanged == true }
    private var isCancelled: Bool { locationDetail.displayAs == "CANCELLED_CALL" }

    private var delayMinutes: Int? {
      TimeUtils.delayMinutes(
        bookedHHmm: locationDetail.gbttBookedDeparture,
        realtimeHHmm: locationDetail.realtimeDeparture
      )
    }

    private var status: ServiceStatus {
      if isCancelled { return .cancelled }
      if let delay = delayMinutes {
        if delay > 0 { return .delayed(delay) }
      }
      if locationDetail.realtimeActivated == true { return .onTime }
      return .scheduled
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

        // Destination + status
        VStack(alignment: .leading, spacing: 4) {
          Text(destination)
            .font(.body)
            .fontWeight(confirmed ? .semibold : .regular)
            .foregroundStyle(isCancelled ? .secondary : .primary)
            .strikethrough(isCancelled)

          HStack(spacing: 6) {
            Text(item.atocName ?? "")
              .font(.subheadline)
              .foregroundStyle(.secondary)

            StatusBadge(status: status)

            if changed {
              CapsuleBadge(text: L10n.changedBadge, style: .orange)
                .accessibilityLabel(L10n.platformChangedA11y)
            }
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        // Platform badge
        PlatformBadge(
          platform: locationDetail.platform,
          isConfirmed: confirmed,
          isCancelled: isCancelled
        )
      }
      .padding(.vertical, 2)
      .accessibilityElement(children: .combine)
      .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
      var parts = [scheduledTime, destination, item.atocName ?? ""]
      switch status {
      case .onTime: parts.append(L10n.statusOnTime)
      case .delayed(let m): parts.append(L10n.delayA11y(m))
      case .cancelled: parts.append(L10n.statusCancelled)
      case .scheduled: break
      }
      if confirmed, let p = locationDetail.platform, !p.isEmpty {
        parts.append(L10n.platformConfirmedA11y(p))
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

    private var isCancelled: Bool { locationDetail.displayAs == "CANCELLED_CALL" }

    private var delayMinutes: Int? {
      TimeUtils.delayMinutes(
        bookedHHmm: locationDetail.gbttBookedArrival,
        realtimeHHmm: locationDetail.realtimeArrival
      )
    }

    private var status: ServiceStatus {
      if isCancelled { return .cancelled }
      if let delay = delayMinutes {
        if delay > 0 { return .delayed(delay) }
      }
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

        VStack(alignment: .leading, spacing: 4) {
          Text(origin)
            .font(.body)
            .fontWeight(.semibold)
            .foregroundStyle(isCancelled ? .secondary : .primary)
            .strikethrough(isCancelled)

          HStack(spacing: 6) {
            Text(item.atocName ?? "")
              .font(.subheadline)
              .foregroundStyle(.secondary)

            StatusBadge(status: status)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)

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

    private var accessibilitySummary: String {
      var parts = [scheduledTime, origin, item.atocName ?? ""]
      switch status {
      case .onTime: parts.append(L10n.statusOnTime)
      case .delayed(let m): parts.append(L10n.delayA11y(m))
      case .cancelled: parts.append(L10n.statusCancelled)
      case .scheduled: break
      }
      if let p = locationDetail.platform, !p.isEmpty {
        parts.append(L10n.arrivalRowA11y(time: scheduledTime, origin: origin, operatorName: "", platform: p))
      }
      return parts.joined(separator: ". ")
    }
  }
}

// MARK: - Service status

enum ServiceStatus {
  case scheduled
  case onTime
  case delayed(Int)
  case cancelled
}

// MARK: - Status badge

private struct StatusBadge: View {
  let status: ServiceStatus

  var body: some View {
    switch status {
    case .scheduled:
      EmptyView()
    case .onTime:
      CapsuleBadge(text: L10n.statusOnTime, style: .green)
    case .delayed(let minutes):
      CapsuleBadge(text: L10n.statusDelayed(minutes), style: .orange)
    case .cancelled:
      CapsuleBadge(text: L10n.statusCancelled, style: .red)
    }
  }
}

// MARK: - Capsule badge (reusable)

struct CapsuleBadge: View {
  let text: String
  let style: BadgeStyle

  enum BadgeStyle {
    case green, orange, red

    var foreground: Color {
      switch self {
      case .green: .green
      case .orange: .orange
      case .red: .red
      }
    }

    var background: Color {
      switch self {
      case .green: Color.green.opacity(0.12)
      case .orange: Color.orange.opacity(0.12)
      case .red: Color.red.opacity(0.12)
      }
    }
  }

  var body: some View {
    Text(text)
      .font(.caption2.weight(.semibold))
      .foregroundStyle(style.foreground)
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
        .font(.title3.weight(isConfirmed ? .bold : .medium))
        .monospacedDigit()
        .foregroundStyle(isConfirmed ? .white : .secondary)
        .frame(minWidth: 34, minHeight: 34)
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
