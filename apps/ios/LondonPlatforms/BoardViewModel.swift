import Combine
import Foundation

@MainActor
final class BoardViewModel: ObservableObject {
  @Published private(set) var services: [ServiceSummary] = []
  @Published var isLoading = false
  @Published var errorMessage: String?
  @Published var lastRefreshLabel: String?
  @Published var showingArrivals = false
  @Published var filterTimeHHmm: String?

  var stationCRS: String
  var stationDesc: String

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
      let f = DateFormatter()
      f.dateFormat = "HH:mm"
      f.timeZone = TimeZone.current
      lastRefreshLabel = f.string(from: Date())
      persistBoardPreferences()
      await TrackedServiceManager.shared.updateFromBoard(
        stationName: stationDesc,
        services: services
      )
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

  /// Large navigation title: station name (short, scales with Dynamic Type).
  var navigationTitle: String { stationDesc }

  /// Context line under the segmented control (time filter state).
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
