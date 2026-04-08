import SwiftUI

/// List row layouts for the main board, sized for Dynamic Type and standard list metrics.
enum ServiceRows {}

extension ServiceRows {
  struct Departure: View {
    let item: ServiceSummary
    let locationDetail: LocationDetail

    private var destination: String {
      locationDetail.destination?.first?.description ?? L10n.emDash
    }

    private var time: String {
      TimeFormatting.displayHHmm(locationDetail.gbttBookedDeparture)
    }

    private var confirmed: Bool { locationDetail.platformConfirmed == true }
    private var changed: Bool { locationDetail.platformChanged == true }

    var body: some View {
      HStack(alignment: .firstTextBaseline, spacing: 12) {
        Text(time)
          .font(.body.monospacedDigit())
          .fontWeight(.medium)
          .foregroundStyle(.secondary)
          .frame(minWidth: 52, alignment: .leading)
          .accessibilitySortPriority(0.5)

        VStack(alignment: .leading, spacing: 4) {
          Text(destination)
            .font(.body)
            .fontWeight(confirmed ? .semibold : .regular)
          HStack(spacing: 8) {
            Text(subtitle)
              .font(.subheadline)
              .foregroundStyle(.secondary)
              .fixedSize(horizontal: false, vertical: true)

            if let delay = delayMinutes, delay > 0 {
              Text("+\(delay)")
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.thinMaterial, in: Capsule())
                .accessibilityLabel(L10n.delayA11y(delay))
            }

            if changed {
              Text(L10n.changedBadge)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.thinMaterial, in: Capsule())
                .accessibilityLabel(L10n.platformChangedA11y)
            }
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        platformTrailing
      }
      .padding(.vertical, 2)
      .accessibilityElement(children: .combine)
      .accessibilityLabel(departureAccessibilitySummary)
    }

    private var departureAccessibilitySummary: String {
      if confirmed, let p = locationDetail.platform, !p.isEmpty {
        return "\(time). \(destination). \(subtitle). \(L10n.platformConfirmedA11y(p))"
      }
      return "\(time). \(destination). \(subtitle)"
    }

    private var delayMinutes: Int? {
      TimeUtils.delayMinutes(
        bookedHHmm: locationDetail.gbttBookedDeparture,
        realtimeHHmm: locationDetail.realtimeDeparture
      )
    }

    @ViewBuilder
    private var platformTrailing: some View {
      if confirmed, let text = locationDetail.platform, !text.isEmpty {
        HStack(spacing: 4) {
          Image(systemName: "checkmark.circle.fill")
            .font(.caption)
            .foregroundStyle(.green)
          Text(text)
            .font(.title2.weight(.bold))
            .monospacedDigit()
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .accessibilityHidden(true)
      }
    }

    private var subtitle: String {
      let base = item.atocName ?? ""
      if confirmed {
        return L10n.departureSubtitleConfirmed(operatorName: base)
      }
      if let p = locationDetail.platform, !p.isEmpty {
        return L10n.departureSubtitlePending(operatorName: base, platform: p)
      }
      return base
    }
  }

  struct Arrival: View {
    let item: ServiceSummary
    let locationDetail: LocationDetail

    private var origin: String {
      locationDetail.origin?.first?.description ?? L10n.emDash
    }

    private var time: String {
      TimeFormatting.displayHHmm(locationDetail.destination?.first?.publicTime)
    }

    var body: some View {
      HStack(alignment: .firstTextBaseline, spacing: 12) {
        Text(time)
          .font(.body.monospacedDigit())
          .fontWeight(.medium)
          .foregroundStyle(.secondary)
          .frame(minWidth: 52, alignment: .leading)

        VStack(alignment: .leading, spacing: 4) {
          Text(origin)
            .font(.body)
            .fontWeight(.semibold)
          Text(item.atocName ?? "")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        Group {
          if let p = locationDetail.platform, !p.isEmpty {
            Text(p)
              .font(.title3)
              .monospacedDigit()
              .lineLimit(1)
              .minimumScaleFactor(0.6)
              .accessibilityHidden(true)
          } else {
            Text(L10n.emDash)
              .font(.body)
              .foregroundStyle(.tertiary)
          }
        }
      }
      .padding(.vertical, 2)
      .accessibilityElement(children: .combine)
      .accessibilityLabel(arrivalAccessibilitySummary)
    }

    private var arrivalAccessibilitySummary: String {
      let op = item.atocName ?? ""
      if let p = locationDetail.platform, !p.isEmpty {
        return L10n.arrivalRowA11y(time: time, origin: origin, operatorName: op, platform: p)
      }
      return L10n.arrivalRowA11yNoPlatform(time: time, origin: origin, operatorName: op)
    }
  }
}

// MARK: - Confirmed departure row accent

extension View {
  /// Subtle leading accent for confirmed departures — tints the row without a heavy background fill.
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
