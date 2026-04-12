import Foundation

struct Station: Hashable, Identifiable {
  var id: String { crs }
  let crs: String
  let displayName: String
}

enum StationCatalog {
  private static let cacheKey = "cachedStations"

  /// All available stations. Starts with the hardcoded London termini fallback,
  /// upgraded to the full UK catalog after `refreshInBackground()` completes.
  static var stations: [Station] {
    if let cached = loadFromCache(), !cached.isEmpty { return cached }
    return fallbackStations
  }

  static func station(crs: String) -> Station {
    stations.first { $0.crs == crs } ?? Station(crs: crs, displayName: crs)
  }

  /// Fetches `/data/stops` in the background and persists the result.
  /// Call once on app launch; the updated catalog is available on the next
  /// call to `stations` after the task completes.
  static func refreshInBackground() {
    Task {
      await RTTClient.shared.fetchAndCacheStops()
    }
  }

  /// Called by `RTTClient` after a successful `/data/stops` fetch.
  static func updateCache(_ stations: [Station]) {
    let dicts = stations.map { ["crs": $0.crs, "name": $0.displayName] }
    UserDefaults.standard.set(dicts, forKey: cacheKey)
  }

  private static func loadFromCache() -> [Station]? {
    guard let raw = UserDefaults.standard.array(forKey: cacheKey) as? [[String: String]] else {
      return nil
    }
    return raw.compactMap { dict in
      guard let crs = dict["crs"], let name = dict["name"] else { return nil }
      return Station(crs: crs, displayName: name)
    }
  }

  // MARK: - Fallback (London termini used until catalog loads)

  private static let fallbackStations: [Station] = [
    Station(crs: "BFR", displayName: "Blackfriars"),
    Station(crs: "CST", displayName: "Cannon Street"),
    Station(crs: "CHX", displayName: "Charing Cross"),
    Station(crs: "CTK", displayName: "City Thameslink"),
    Station(crs: "EUS", displayName: "Euston"),
    Station(crs: "FST", displayName: "Fenchurch Street"),
    Station(crs: "KGX", displayName: "Kings Cross"),
    Station(crs: "LST", displayName: "Liverpool Street"),
    Station(crs: "LBG", displayName: "London Bridge"),
    Station(crs: "MYB", displayName: "Marylebone"),
    Station(crs: "MOG", displayName: "Moorgate"),
    Station(crs: "OLD", displayName: "Old Street"),
    Station(crs: "PAD", displayName: "Paddington"),
    Station(crs: "STP", displayName: "St Pancras (Domestic)"),
    Station(crs: "VXH", displayName: "Vauxhall"),
    Station(crs: "VIC", displayName: "Victoria"),
    Station(crs: "WAT", displayName: "Waterloo"),
    Station(crs: "WAE", displayName: "Waterloo East"),
  ]
}
