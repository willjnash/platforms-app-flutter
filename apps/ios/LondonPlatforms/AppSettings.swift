import Foundation

enum AppSettings {
  private static let stationKey = "savedStation"
  private static let stationDescKey = "savedStationDesc"
  private static let showingArrivalsKey = "savedShowingArrivals"
  private static let timeFilterKey = "savedTimeFilterHHmm"
  private static let filterToCRSKey = "savedFilterToCRS"
  private static let showNonStoppingKey = "savedShowNonStoppingTrains"

  static var savedCRS: String {
    get { UserDefaults.standard.string(forKey: stationKey) ?? "EUS" }
    set { UserDefaults.standard.set(newValue, forKey: stationKey) }
  }

  static var savedStationDescription: String {
    get { UserDefaults.standard.string(forKey: stationDescKey) ?? "Euston" }
    set { UserDefaults.standard.set(newValue, forKey: stationDescKey) }
  }

  static func applyStation(_ station: Station) {
    savedCRS = station.crs
    savedStationDescription = station.displayName
  }

  static var savedShowingArrivals: Bool {
    get { UserDefaults.standard.object(forKey: showingArrivalsKey) as? Bool ?? false }
    set { UserDefaults.standard.set(newValue, forKey: showingArrivalsKey) }
  }

  static var savedTimeFilterHHmm: String? {
    get { UserDefaults.standard.string(forKey: timeFilterKey) }
    set {
      if let newValue, !newValue.isEmpty {
        UserDefaults.standard.set(newValue, forKey: timeFilterKey)
      } else {
        UserDefaults.standard.removeObject(forKey: timeFilterKey)
      }
    }
  }

  /// CRS code to pass as `filterTo` in location searches, restricting the board
  /// to services that subsequently call at this station.
  static var savedFilterToCRS: String? {
    get { UserDefaults.standard.string(forKey: filterToCRSKey) }
    set {
      if let newValue, !newValue.isEmpty {
        UserDefaults.standard.set(newValue, forKey: filterToCRSKey)
      } else {
        UserDefaults.standard.removeObject(forKey: filterToCRSKey)
      }
    }
  }

  /// Whether pass-through (non-stopping) trains are shown on the board.
  static var savedShowNonStoppingTrains: Bool {
    get { UserDefaults.standard.object(forKey: showNonStoppingKey) as? Bool ?? false }
    set { UserDefaults.standard.set(newValue, forKey: showNonStoppingKey) }
  }
}
