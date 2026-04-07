import Foundation

/// UserDefaults keys per SERVICE_SPEC §2.7.
enum AppSettings {
  private static let stationKey = "savedStation"
  private static let stationDescKey = "savedStationDesc"
  private static let showingArrivalsKey = "savedShowingArrivals"
  private static let timeFilterKey = "savedTimeFilterHHmm"

  static var savedCRS: String {
    get {
      UserDefaults.standard.string(forKey: stationKey) ?? "EUS"
    }
    set {
      UserDefaults.standard.set(newValue, forKey: stationKey)
    }
  }

  static var savedStationDescription: String {
    get {
      UserDefaults.standard.string(forKey: stationDescKey) ?? "Euston"
    }
    set {
      UserDefaults.standard.set(newValue, forKey: stationDescKey)
    }
  }

  static func applyStation(_ station: Station) {
    savedCRS = station.crs
    savedStationDescription = station.displayName
  }

  /// Persisted board mode (not in SERVICE_SPEC; improves session continuity).
  static var savedShowingArrivals: Bool {
    get {
      UserDefaults.standard.object(forKey: showingArrivalsKey) as? Bool ?? false
    }
    set {
      UserDefaults.standard.set(newValue, forKey: showingArrivalsKey)
    }
  }

  /// Optional `HHmm` time-of-day filter for search URLs.
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
}
