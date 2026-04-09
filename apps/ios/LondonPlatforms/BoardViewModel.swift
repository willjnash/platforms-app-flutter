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

  // Auto-refresh
  private static let refreshIntervalSeconds = 30
  var autoRefreshCountdown: Int = 0
  private var refreshTask: Task<Void, Never>?

  /// True when showing live boards (no time filter).
  var isLive: Bool { filterTimeHHmm == nil }

  /// 0.0–1.0 progress toward next auto-refresh.
  var autoRefreshProgress: Double {
    guard isLive, autoRefreshCountdown > 0 else { return 0 }
    return 1.0 - (Double(autoRefreshCountdown) / Double(Self.refreshIntervalSeconds))
  }

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

  // MARK: - Auto-refresh

  func startAutoRefresh() {
    stopAutoRefresh()
    guard isLive else { return }
    autoRefreshCountdown = Self.refreshIntervalSeconds
    refreshTask = Task {
      while !Task.isCancelled {
        for i in stride(from: Self.refreshIntervalSeconds, through: 1, by: -1) {
          autoRefreshCountdown = i
          try? await Task.sleep(for: .seconds(1))
          if Task.isCancelled { return }
        }
        autoRefreshCountdown = 0
        await load()
        autoRefreshCountdown = Self.refreshIntervalSeconds
      }
    }
  }

  func stopAutoRefresh() {
    refreshTask?.cancel()
    refreshTask = nil
    autoRefreshCountdown = 0
  }

  // MARK: - Derived

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
