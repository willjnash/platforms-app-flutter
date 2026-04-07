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
    let lines = callingPointLines(from: d.locations)

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
        if lines.isEmpty {
          Text(L10n.noCallingPoints)
            .foregroundStyle(.secondary)
        } else {
          ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
            Text(line)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
      }
    }
    .listStyle(.insetGrouped)
    .refreshable {
      await load()
    }
  }

  /// SERVICE_SPEC §2.4 filtering and line format.
  private func callingPointLines(from locations: [ServiceLocation]?) -> [String] {
    guard let locations else { return [] }
    var lines: [String] = []
    for item in locations {
      guard item.isPublicCall == true else { continue }
      guard let originFirst = item.origin?.first?.description,
            let desc = item.description,
            originFirst != desc else { continue }
      guard item.gbttBookedArrival != nil else { continue }
      let arr = TimeFormatting.displayHHmm(item.gbttBookedArrival)
      var line = "\(desc) (\(arr))"
      if let destFirst = item.destination?.first?.description, destFirst != desc {
        line += ", "
      }
      lines.append(line)
    }
    return lines
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
