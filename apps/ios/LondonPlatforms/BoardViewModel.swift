import Foundation
import Observation

@Observable
@MainActor
final class BoardViewModel {
  private(set) var services: [ServiceSummary] = []
  var isLoading = false
  var errorMessage: String?
  var lastRefreshLabel: String?
  var showingArrivals = false
  var filterTimeHHmm: String?

  var stationCRS: String
  var stationDesc: String

  private static let refreshFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "HH:mm"
    f.timeZone = TimeZone.current
    return f
  }()

  init() {
    stationCRS = AppSettings.savedCRS
    stationDesc = AppSettings.savedStationDescription
    showingArrivals = AppSettings.savedShowingArrivals
    filterTimeHHmm = AppSettings.savedTimeFilterHHmm
  }

  func applyStation(_ station: Station) {
    AppSettings.applyStation(station)
    stationCRS = station.crs
    stationDesc = station.displayName
    persistBoardPreferences()
  }

  func persistBoardPreferences() {
    AppSettings.savedShowingArrivals = showingArrivals
    AppSettings.savedTimeFilterHHmm = filterTimeHHmm
  }

  func load(userInitiated: Bool = false) async {
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }
    do {
      let res = try await RTTClient.shared.fetchBoard(
        crs: stationCRS,
        arrivals: showingArrivals,
        timeHHmm: filterTimeHHmm
      )
      services = res.services ?? []
      lastRefreshLabel = Self.refreshFormatter.string(from: Date())
      persistBoardPreferences()
      if userInitiated {
        Feedback.boardRefreshCompleted(success: true)
      }
    } catch {
      errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
      if userInitiated {
        Feedback.boardRefreshCompleted(success: false)
      }
    }
  }

  var navigationTitle: String { stationDesc }

  var scheduleContextDescription: String {
    if let hhmm = filterTimeHHmm {
      return L10n.scheduleForTimeToday(TimeFormatting.displayHHmm(hhmm))
    }
    return showingArrivals ? L10n.scheduleLiveArrivals : L10n.scheduleLiveDepartures
  }

  func rowIsRenderable(_ item: ServiceSummary) -> Bool {
    guard let ld = item.locationDetail,
          item.serviceUid != nil,
          item.runDate != nil
    else { return false }
    if showingArrivals {
      guard let pub = ld.destination?.first?.publicTime, !pub.isEmpty,
            ld.origin?.first != nil
      else { return false }
      return true
    }
    guard let gb = ld.gbttBookedDeparture, !gb.isEmpty,
          ld.destination?.first != nil
    else { return false }
    return true
  }

  var filteredServices: [ServiceSummary] {
    services.filter { rowIsRenderable($0) }
  }
}
