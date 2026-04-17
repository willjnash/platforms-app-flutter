import Foundation
import Observation

@Observable
@MainActor
final class BoardViewModel {
  private(set) var services: [ServiceSummary] = []
  private(set) var systemStatus: SystemStatus?
  var isLoading = false
  var errorMessage: String?
  var lastRefreshLabel: String?
  var showingArrivals = false
  var filterTimeHHmm: String?
  var filterToCRS: String?      // CRS of the "towards" station filter

  var stationCRS: String
  var stationDesc: String

  // Auto-refresh
  private static let refreshIntervalSeconds = 30

  // Delayed-train retention
  /// How far back (in minutes) to look when priming the service list on first
  /// load. Matches the window needed to catch trains that fell off the live
  /// board due to delay.
  private static let primerLookbackMinutes = 60
  /// Maximum age (in minutes past effective departure) of a retained service.
  /// Trains older than this are dropped rather than kept indefinitely.
  private static let retainedServiceLookbackMinutes = 120
  var autoRefreshCountdown: Int = 0
  private var refreshTask: Task<Void, Never>?

  var isLive: Bool { filterTimeHHmm == nil }

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
    filterToCRS = AppSettings.savedFilterToCRS
  }

  func applyStation(_ station: Station) {
    AppSettings.applyStation(station)
    stationCRS = station.crs
    stationDesc = station.displayName
    resetBoard()
    persistBoardPreferences()
  }

  /// Clears the service list so the next `load()` starts fresh.
  /// Call this whenever the board context changes (station, mode, filters).
  func resetBoard() {
    services = []
  }

  func persistBoardPreferences() {
    AppSettings.savedShowingArrivals = showingArrivals
    AppSettings.savedTimeFilterHHmm = filterTimeHHmm
    AppSettings.savedFilterToCRS = filterToCRS
  }

  func load(userInitiated: Bool = false) async {
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }
    do {
      // Primer fetch: when entering live departures mode with no existing
      // services (cold start, station change, mode switch), fetch the past
      // hour to seed the retain pool with any delayed un-departed trains.
      if services.isEmpty, !showingArrivals, filterTimeHHmm == nil,
         let primerHHmm = TimeUtils.hhmmOffset(minutes: -Self.primerLookbackMinutes) {
        if let primer = try? await RTTClient.shared.fetchBoard(
          crs: stationCRS,
          arrivals: false,
          timeHHmm: primerHHmm,
          filterToCRS: filterToCRS
        ) {
          services = primer.services ?? []
        }
      }

      let res = try await RTTClient.shared.fetchBoard(
        crs: stationCRS,
        arrivals: showingArrivals,
        timeHHmm: filterTimeHHmm,
        filterToCRS: filterToCRS
      )
      services = mergeWithRetained(newServices: res.services ?? [])
      systemStatus = res.systemStatus
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
    // Hide empty coaching stock and other non-passenger moves
    if item.inPassengerService == false { return false }

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

    // Pass-through trains (non-stopping): show only when the setting is on
    if AppSettings.savedShowNonStoppingTrains,
       let pass = ld.passHHmm, !pass.isEmpty,
       ld.destination?.first != nil {
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

  // MARK: - Delayed train retention

  /// Merges `newServices` (fresh API response) with any services from the
  /// previous fetch that have been dropped by the API due to delay but have
  /// not yet actually departed.
  ///
  /// Only active in live departures mode (`!showingArrivals && filterTimeHHmm == nil`).
  private func mergeWithRetained(newServices: [ServiceSummary]) -> [ServiceSummary] {
    guard !showingArrivals, filterTimeHHmm == nil, !services.isEmpty else {
      return newServices
    }
    let newIDs = Set(newServices.map { $0.id })
    let currentMinutes = TimeUtils.currentMinutesSinceMidnight() ?? 0
    let retained = services.filter { prev in
      // Skip if already in the fresh response
      guard !newIDs.contains(prev.id) else { return false }
      // Skip if the train has actually departed
      guard prev.locationDetail?.realtimeDepartureActual != true else { return false }
      // Drop if the effective departure time is too far in the past
      let effectiveTime = prev.locationDetail?.realtimeDeparture
        ?? prev.locationDetail?.gbttBookedDeparture
      let sortKey = TimeUtils.minutesSinceMidnightForSorting(effectiveTime, currentMinutes: currentMinutes)
      return sortKey >= currentMinutes - Self.retainedServiceLookbackMinutes
    }
    guard !retained.isEmpty else { return newServices }
    return (newServices + retained).sorted { a, b in
      let at = TimeUtils.minutesSinceMidnightForSorting(
        a.locationDetail?.realtimeDeparture ?? a.locationDetail?.gbttBookedDeparture,
        currentMinutes: currentMinutes)
      let bt = TimeUtils.minutesSinceMidnightForSorting(
        b.locationDetail?.realtimeDeparture ?? b.locationDetail?.gbttBookedDeparture,
        currentMinutes: currentMinutes)
      return at < bt
    }
  }
}
