import SwiftUI

/// Snapshot of the board row used to open service detail, so the headline time matches the list.
struct ServiceDetailBoardContext: Hashable {
  let locationDetail: LocationDetail
  let showingArrivals: Bool
}

struct ServiceDetailView: View {
  let serviceUid: String
  let runDate: String
  /// When set (normal board tap), headline time matches the board row; `nil` for nested association sheets.
  let boardContext: ServiceDetailBoardContext?

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
        ServiceDetailView(serviceUid: uid, runDate: rd, boardContext: nil)
          .presentationDragIndicator(.visible)
          .presentationDetents([.medium, .large])
      }
    }
  }

  init(serviceUid: String, runDate: String, boardContext: ServiceDetailBoardContext? = nil) {
    self.serviceUid = serviceUid
    self.runDate = runDate
    self.boardContext = boardContext
  }

  private func detailList(_ d: ServiceDetailResponse) -> some View {
    let destName = d.destination?.first?.description
    let callingPoints = Self.callingPointRows(from: d.locations)
    let headlineTime: String? = {
      if let boardContext {
        return Self.boardPrimaryTime(
          locationDetail: boardContext.locationDetail,
          showingArrivals: boardContext.showingArrivals
        )
      }
      return callingPoints.first { $0.progress == .current }?.arrivalDisplay
        ?? callingPoints.first { $0.progress == .next }?.arrivalDisplay
        ?? callingPoints.first?.arrivalDisplay
    }()
    let headline: String? = {
      guard let headlineTime, let destName else { return nil }
      return "\(headlineTime) to \(destName)"
    }()
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
              .callingPointCurrentRowBackground(isCurrent: row.progress == .current)
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

  /// Primary clock time shown on the board for this row (matches `ServiceRows.Departure` / `ServiceRows.Arrival`).
  private static func boardPrimaryTime(locationDetail: LocationDetail, showingArrivals: Bool) -> String {
    if showingArrivals {
      return TimeFormatting.displayHHmm(locationDetail.destination?.first?.publicTime)
    }
    return TimeFormatting.displayHHmm(locationDetail.gbttBookedDeparture ?? locationDetail.passHHmm)
  }

  private static func callingPointRows(from locations: [ServiceLocation]?) -> [CallingPointRow] {
    guard let locations else { return [] }
    struct Built {
      let id: String
      let loc: ServiceLocation
      let stationName: String
      let arrivalDisplay: String
      let expectedArrivalDisplay: String?
      let platform: String?
      let platformConfirmed: Bool
      let towardDestination: String?
      let isCancelled: Bool
      let isRequestStop: Bool
      let delayReason: String?
      let primaryRealtimeStatus: String?
    }
    var built: [Built] = []
    for (index, item) in locations.enumerated() {
      guard item.isPublicCall == true else { continue }
      guard let desc = item.description else { continue }
      guard let rawBooked = item.gbttBookedArrival ?? item.gbttBookedDeparture else { continue }

      let isCancelled = item.displayAs == "CANCELLED"
      let realtime = item.realtimeArrival ?? item.realtimeDeparture
      let expectedDiffers = realtime != nil && realtime != rawBooked

      let toward: String? = {
        guard let destFirst = item.destination?.first?.description, destFirst != desc else { return nil }
        return destFirst
      }()

      built.append(
        Built(
          id: "\(index)-\(desc)-\(rawBooked)",
          loc: item,
          stationName: desc,
          arrivalDisplay: TimeFormatting.displayHHmm(rawBooked),
          expectedArrivalDisplay: expectedDiffers ? TimeFormatting.displayHHmm(realtime) : nil,
          platform: item.platform,
          platformConfirmed: item.platformConfirmed == true,
          towardDestination: toward,
          isCancelled: isCancelled,
          isRequestStop: item.isRequestStop == true,
          delayReason: (isCancelled || (realtime != nil && realtime != rawBooked))
            ? item.delayReason : nil,
          primaryRealtimeStatus: item.departureStatus ?? item.arrivalStatus
        )
      )
    }

    let progresses = CallingPointProgress.values(for: built.map(\.loc))
    return zip(built, progresses).map { b, progress in
      CallingPointRow(
        id: b.id,
        stationName: b.stationName,
        arrivalDisplay: b.arrivalDisplay,
        expectedArrivalDisplay: b.expectedArrivalDisplay,
        platform: b.platform,
        platformConfirmed: b.platformConfirmed,
        towardDestination: b.towardDestination,
        isCancelled: b.isCancelled,
        isRequestStop: b.isRequestStop,
        delayReason: b.delayReason,
        primaryRealtimeStatus: b.primaryRealtimeStatus,
        progress: progress
      )
    }
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
  let primaryRealtimeStatus: String?
  let progress: CallingPointProgress
}

private struct CallingPointRowView: View {
  let row: CallingPointRow

  private var stationForeground: Color {
    if row.isCancelled { return .secondary }
    if row.progress == .passed { return .secondary }
    return .primary
  }

  private var showsLiveStatusChip: Bool {
    guard let s = row.primaryRealtimeStatus else { return false }
    return [
      "APPROACHING", "ARRIVING", "AT_PLATFORM", "DEPARTING",
      "DEPART_PREPARING", "DEPART_READY",
    ].contains(s)
  }

  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      progressLeading
        .frame(width: 26, alignment: .center)
        .padding(.top, 2)

      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 4) {
          Text(row.stationName)
            .font(.body)
            .foregroundStyle(stationForeground)
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

        if row.progress == .current && !row.isCancelled {
          HStack(spacing: 4) {
            if showsLiveStatusChip {
              LiveStatusChip(liveStatus: row.primaryRealtimeStatus)
            } else {
              CapsuleBadge(text: L10n.callingPointHere, style: .green)
            }
          }
        } else if row.progress == .next && !row.isCancelled {
          CapsuleBadge(text: L10n.callingPointProgressNext, style: .blue)
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
        toward: row.towardDestination,
        progress: row.progress
      )
    )
  }

  @ViewBuilder
  private var progressLeading: some View {
    switch row.progress {
    case .current:
      Image(systemName: "train.side.front.car")
        .font(.title3)
        .foregroundStyle(.green)
        .accessibilityHidden(true)
    case .next:
      Image(systemName: "arrow.forward.circle.fill")
        .font(.title3)
        .foregroundStyle(.blue)
        .accessibilityHidden(true)
    case .passed:
      Image(systemName: "checkmark.circle.fill")
        .font(.caption)
        .foregroundStyle(.tertiary)
        .accessibilityHidden(true)
    case .upcoming:
      Color.clear
        .frame(width: 1, height: 1)
        .accessibilityHidden(true)
    }
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

// MARK: - List row styling

private extension View {
  @ViewBuilder
  func callingPointCurrentRowBackground(isCurrent: Bool) -> some View {
    if isCurrent {
      self.listRowBackground(Color.green.opacity(0.10))
    } else {
      self
    }
  }
}
