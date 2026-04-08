import SwiftUI

struct ServiceDetailView: View {
  let serviceUid: String
  let runDate: String

  @State private var detail: ServiceDetailResponse?
  @State private var isLoading = false
  @State private var errorMessage: String?

  var body: some View {
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
    let callingPoints = Self.callingPointRows(from: d.locations)

    return List {
      Section {
        LabeledContent(L10n.headcode) {
          Text(d.trainIdentity ?? L10n.emDash)
            .monospaced()
        }
        LabeledContent(L10n.trainOperator) {
          Text(d.atocName ?? L10n.emDash)
        }
      }

      if let headline {
        Section(L10n.routeSection) {
          Text(headline)
            .font(.headline)
            .fixedSize(horizontal: false, vertical: true)
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

  /// SERVICE_SPEC §2.4 filtering. Presentation uses a split station / time row plus optional “toward” caption.
  private static func callingPointRows(from locations: [ServiceLocation]?) -> [CallingPointRow] {
    guard let locations else { return [] }
    var rows: [CallingPointRow] = []
    for (index, item) in locations.enumerated() {
      guard item.isPublicCall == true else { continue }
      guard let originFirst = item.origin?.first?.description,
            let desc = item.description,
            originFirst != desc else { continue }
      guard let rawArrival = item.gbttBookedArrival else { continue }
      let toward: String? = {
        guard let destFirst = item.destination?.first?.description, destFirst != desc else { return nil }
        return destFirst
      }()
      rows.append(
        CallingPointRow(
          id: "\(index)-\(desc)-\(rawArrival)",
          stationName: desc,
          arrivalDisplay: TimeFormatting.displayHHmm(rawArrival),
          towardDestination: toward
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

// MARK: - Calling points (§2.4)

private struct CallingPointRow: Identifiable {
  let id: String
  let stationName: String
  let arrivalDisplay: String
  let towardDestination: String?
}

private struct CallingPointRowView: View {
  let row: CallingPointRow

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(alignment: .firstTextBaseline, spacing: 12) {
        Text(row.stationName)
          .font(.body)
          .foregroundStyle(.primary)
          .multilineTextAlignment(.leading)
          .frame(maxWidth: .infinity, alignment: .leading)

        Text(row.arrivalDisplay)
          .font(.subheadline)
          .monospacedDigit()
          .foregroundStyle(.secondary)
          .layoutPriority(1)
      }

      if let toward = row.towardDestination {
        Text(L10n.callingPointToward(toward))
          .font(.caption)
          .foregroundStyle(.tertiary)
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
