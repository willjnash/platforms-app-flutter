import SwiftUI

struct ServiceDetailView: View {
  let serviceUid: String
  let runDate: String

  @State private var detail: ServiceDetailResponse?
  @State private var isLoading = false
  @State private var errorMessage: String?
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Group {
        if isLoading && detail == nil {
          ProgressView(L10n.loading)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let err = errorMessage {
          ContentUnavailableView(
            L10n.couldNotLoadService,
            systemImage: "wifi.exclamationmark",
            description: Text(err)
          )
        } else if let detail {
          detailList(detail)
        } else {
          ContentUnavailableView(
            L10n.noData,
            systemImage: "train.side.front.car",
            description: Text(L10n.pullToRefreshHint)
          )
        }
      }
      .navigationTitle(L10n.serviceNavTitle)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(L10n.done) { dismiss() }
        }
      }
    }
    .task {
      await load()
    }
  }

  private func detailList(_ d: ServiceDetailResponse) -> some View {
    let originTime = d.origin?.first?.publicTime
    let destName = d.destination?.first?.description
    let headline: String? = {
      guard let originTime, let destName else { return nil }
      return "\(TimeFormatting.displayHHmm(originTime)) to \(destName)"
    }()
    let callingPoints = Self.callingPointRows(from: d.locations, originDescription: d.origin?.first?.description)

    return List {
      Section {
        if let headline {
          Text(headline)
            .font(.headline)
            .fixedSize(horizontal: false, vertical: true)
        }
        LabeledContent(L10n.headcode) {
          Text(d.trainIdentity ?? L10n.emDash)
            .monospaced()
        }
        LabeledContent(L10n.trainOperator) {
          Text(d.atocName ?? L10n.emDash)
        }
      }

      Section(L10n.callingPoints) {
        if callingPoints.isEmpty {
          Text(L10n.noCallingPoints)
            .foregroundStyle(.secondary)
        } else {
          ForEach(callingPoints) { row in
            CallingPointRowView(row: row)
          }
        }
      }
    }
    .listStyle(.insetGrouped)
    .refreshable {
      await load()
    }
  }

  private static func callingPointRows(
    from locations: [ServiceLocation]?,
    originDescription: String?
  ) -> [CallingPointRow] {
    guard let locations else { return [] }
    var rows: [CallingPointRow] = []
    for (index, item) in locations.enumerated() {
      guard item.isPublicCall == true else { continue }
      guard let desc = item.description, desc != originDescription else { continue }
      guard let rawArrival = item.gbttBookedArrival else { continue }

      let isCancelled = item.displayAs == "CANCELLED"
      let realtimeArrival = item.realtimeArrival
      let expectedDiffers = realtimeArrival != nil && realtimeArrival != rawArrival

      let toward: String? = {
        guard let destFirst = item.destination?.first?.description, destFirst != desc else { return nil }
        return destFirst
      }()

      rows.append(
        CallingPointRow(
          id: "\(index)-\(desc)-\(rawArrival)",
          stationName: desc,
          arrivalDisplay: TimeFormatting.displayHHmm(rawArrival),
          expectedArrivalDisplay: expectedDiffers ? TimeFormatting.displayHHmm(realtimeArrival) : nil,
          platform: item.platform,
          platformConfirmed: item.platformConfirmed == true,
          towardDestination: toward,
          isCancelled: isCancelled
        )
      )
    }
    return rows
  }

  private func load() async {
    if detail == nil { isLoading = true }
    errorMessage = nil
    defer { isLoading = false }
    do {
      detail = try await RTTClient.shared.fetchServiceDetail(serviceUid: serviceUid, runDate: runDate)
    } catch {
      errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
  }
}

// MARK: - Calling points

private struct CallingPointRow: Identifiable {
  let id: String
  let stationName: String
  let arrivalDisplay: String
  let expectedArrivalDisplay: String?
  let platform: String?
  let platformConfirmed: Bool
  let towardDestination: String?
  let isCancelled: Bool
}

private struct CallingPointRowView: View {
  let row: CallingPointRow

  var body: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 2) {
        Text(row.stationName)
          .font(.body)
          .foregroundStyle(row.isCancelled ? .secondary : .primary)
          .strikethrough(row.isCancelled)

        if let toward = row.towardDestination {
          Text(L10n.callingPointToward(toward))
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      VStack(alignment: .trailing, spacing: 2) {
        Text(row.arrivalDisplay)
          .font(.subheadline)
          .monospacedDigit()
          .foregroundStyle(row.isCancelled ? .tertiary : .secondary)
          .strikethrough(row.isCancelled)

        if let exp = row.expectedArrivalDisplay, !row.isCancelled {
          Text(exp)
            .font(.caption.monospacedDigit().weight(.semibold))
            .foregroundStyle(.orange)
        }
      }
      .layoutPriority(1)

      if let p = row.platform, !p.isEmpty, !row.isCancelled {
        PlatformBadge(platform: p, isConfirmed: row.platformConfirmed, isCancelled: false)
          .scaleEffect(0.85)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
      L10n.callingPointRowAccessibility(
        station: row.stationName,
        time: row.arrivalDisplay,
        toward: row.towardDestination
      )
    )
  }
}
