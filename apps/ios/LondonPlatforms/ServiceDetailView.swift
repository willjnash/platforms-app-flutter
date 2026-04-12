import SwiftUI

struct ServiceDetailView: View {
  let serviceUid: String
  let runDate: String

  @State private var detail: ServiceDetailResponse?
  @State private var isLoading = false
  @State private var errorMessage: String?
  @State private var associationToShow: ServiceAssociation?
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
    .sheet(item: $associationToShow) { assoc in
      if let uid = assoc.serviceUid, let rd = assoc.runDate {
        ServiceDetailView(serviceUid: uid, runDate: rd)
          .presentationDragIndicator(.visible)
          .presentationDetents([.medium, .large])
      }
    }
  }

  private func detailList(_ d: ServiceDetailResponse) -> some View {
    let originTime = d.origin?.first?.publicTime
    let destName = d.destination?.first?.description
    let headline: String? = {
      guard let originTime, let destName else { return nil }
      return "\(TimeFormatting.displayHHmm(originTime)) to \(destName)"
    }()
    let callingPoints = Self.callingPointRows(
      from: d.locations,
      originDescription: d.origin?.first?.description
    )
    let associations = Self.allAssociations(from: d.locations)

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
        if let reason = d.delayReason {
          LabeledContent(L10n.delayReasonLabel) {
            Text(reason)
              .foregroundStyle(.orange)
              .multilineTextAlignment(.trailing)
          }
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

      if !associations.isEmpty {
        Section(L10n.associationsSection) {
          ForEach(associations) { assoc in
            Button {
              associationToShow = assoc
            } label: {
              AssociationRowView(association: assoc)
            }
            .tint(.primary)
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
          isCancelled: isCancelled,
          isRequestStop: item.isRequestStop == true,
          delayReason: (isCancelled || (realtimeArrival != nil && realtimeArrival != rawArrival))
            ? item.delayReason : nil
        )
      )
    }
    return rows
  }

  /// Collects all public associations across every calling point.
  private static func allAssociations(from locations: [ServiceLocation]?) -> [ServiceAssociation] {
    guard let locations else { return [] }
    var seen = Set<String>()
    return locations.flatMap { $0.associations }.filter { assoc in
      guard assoc.isPublic else { return false }
      return seen.insert(assoc.id).inserted
    }
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
  let isRequestStop: Bool
  let delayReason: String?
}

private struct CallingPointRowView: View {
  let row: CallingPointRow

  var body: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 4) {
          Text(row.stationName)
            .font(.body)
            .foregroundStyle(row.isCancelled ? .secondary : .primary)
            .strikethrough(row.isCancelled)

          if row.isRequestStop {
            Text(L10n.requestStopBadge)
              .font(.caption2.weight(.semibold))
              .foregroundStyle(.teal)
              .padding(.horizontal, 4)
              .padding(.vertical, 1)
              .background(Color.teal.opacity(0.12), in: Capsule())
          }
        }

        if let toward = row.towardDestination {
          Text(L10n.callingPointToward(toward))
            .font(.caption)
            .foregroundStyle(.tertiary)
        }

        if let reason = row.delayReason, !row.isCancelled {
          Text(reason)
            .font(.caption)
            .foregroundStyle(.orange)
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

// MARK: - Associations

private struct AssociationRowView: View {
  let association: ServiceAssociation

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: associationIcon)
        .foregroundStyle(.secondary)
        .frame(width: 20)

      VStack(alignment: .leading, spacing: 2) {
        Text(associationLabel)
          .font(.body)

        if let op = association.operatorName {
          Text(op)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      Spacer()

      Image(systemName: "chevron.right")
        .font(.caption)
        .foregroundStyle(.tertiary)
    }
  }

  private var associationIcon: String {
    switch association.type {
    case "JOIN_FROM", "JOIN_INTO": return "arrow.triangle.merge"
    case "DIVIDE_INTO", "DIVIDE_FROM": return "arrow.triangle.branch"
    case "FORM_INTO", "FORM_FROM": return "arrow.right"
    default: return "arrow.right"
    }
  }

  private var associationLabel: String {
    let headcode = association.headcode ?? association.serviceUid ?? L10n.emDash
    switch association.type {
    case "JOIN_FROM": return L10n.associationJoinFrom(headcode)
    case "JOIN_INTO": return L10n.associationJoinInto(headcode)
    case "DIVIDE_INTO": return L10n.associationDivideInto(headcode)
    case "DIVIDE_FROM": return L10n.associationDivideFrom(headcode)
    case "FORM_INTO": return L10n.associationFormInto(headcode)
    case "FORM_FROM": return L10n.associationFormFrom(headcode)
    default: return headcode
    }
  }
}
