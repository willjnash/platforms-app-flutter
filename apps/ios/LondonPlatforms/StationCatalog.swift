import CoreLocation
import Foundation

struct Station: Hashable, Identifiable {
  var id: String { crs }
  let crs: String
  let displayName: String
  let latitude: Double?
  let longitude: Double?

  init(crs: String, displayName: String, latitude: Double? = nil, longitude: Double? = nil) {
    self.crs = crs
    self.displayName = displayName
    self.latitude = latitude
    self.longitude = longitude
  }

  var location: CLLocation? {
    guard let latitude, let longitude else { return nil }
    return CLLocation(latitude: latitude, longitude: longitude)
  }
}

enum StationCatalog {
  private static let cacheKey = "cachedStations"

  /// All available stations. Starts with the hardcoded London termini fallback,
  /// upgraded to the full UK catalog after `refreshInBackground()` completes.
  static var stations: [Station] {
    if let cached = loadFromCache(), !cached.isEmpty {
      return cached.map(applyKnownCoordinates)
    }
    return fallbackStations
  }

  static func station(crs: String) -> Station {
    stations.first { $0.crs == crs } ?? applyKnownCoordinates(Station(crs: crs, displayName: crs))
  }

  static func nearestStations(to userLocation: CLLocation, limit: Int = 8) -> [(station: Station, distance: CLLocationDistance)] {
    stations
      .compactMap { station -> (station: Station, distance: CLLocationDistance)? in
        guard let stationLocation = station.location else { return nil }
        return (station, userLocation.distance(from: stationLocation))
      }
      .sorted { $0.distance < $1.distance }
      .prefix(limit)
      .map { $0 }
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
    let dicts = stations.map { station -> [String: String] in
      var dict = ["crs": station.crs, "name": station.displayName]
      if let latitude = station.latitude {
        dict["lat"] = String(latitude)
      }
      if let longitude = station.longitude {
        dict["lon"] = String(longitude)
      }
      return dict
    }
    UserDefaults.standard.set(dicts, forKey: cacheKey)
  }

  private static func loadFromCache() -> [Station]? {
    guard let raw = UserDefaults.standard.array(forKey: cacheKey) as? [[String: String]] else {
      return nil
    }
    return raw.compactMap { dict in
      guard let crs = dict["crs"], let name = dict["name"] else { return nil }
      let latitude = dict["lat"].flatMap(Double.init)
      let longitude = dict["lon"].flatMap(Double.init)
      return Station(crs: crs, displayName: name, latitude: latitude, longitude: longitude)
    }
  }

  private static func applyKnownCoordinates(_ station: Station) -> Station {
    guard station.latitude == nil || station.longitude == nil else { return station }
    guard let (latitude, longitude) = knownCoordinates[station.crs] else { return station }
    return Station(
      crs: station.crs,
      displayName: station.displayName,
      latitude: latitude,
      longitude: longitude
    )
  }

  // MARK: - Fallback (London termini used until catalog loads)

  private static let fallbackStations: [Station] = [
    Station(crs: "BFR", displayName: "Blackfriars", latitude: 51.5116, longitude: -0.1033),
    Station(crs: "CST", displayName: "Cannon Street", latitude: 51.5114, longitude: -0.0904),
    Station(crs: "CHX", displayName: "Charing Cross", latitude: 51.5070, longitude: -0.1247),
    Station(crs: "CTK", displayName: "City Thameslink", latitude: 51.5142, longitude: -0.1036),
    Station(crs: "EUS", displayName: "Euston", latitude: 51.5282, longitude: -0.1337),
    Station(crs: "FST", displayName: "Fenchurch Street", latitude: 51.5115, longitude: -0.0789),
    Station(crs: "KGX", displayName: "Kings Cross", latitude: 51.5308, longitude: -0.1238),
    Station(crs: "LST", displayName: "Liverpool Street", latitude: 51.5178, longitude: -0.0823),
    Station(crs: "LBG", displayName: "London Bridge", latitude: 51.5052, longitude: -0.0861),
    Station(crs: "MYB", displayName: "Marylebone", latitude: 51.5225, longitude: -0.1636),
    Station(crs: "MOG", displayName: "Moorgate", latitude: 51.5185, longitude: -0.0887),
    Station(crs: "OLD", displayName: "Old Street", latitude: 51.5263, longitude: -0.0873),
    Station(crs: "PAD", displayName: "Paddington", latitude: 51.5152, longitude: -0.1754),
    Station(crs: "STP", displayName: "St Pancras (Domestic)", latitude: 51.5319, longitude: -0.1264),
    Station(crs: "VXH", displayName: "Vauxhall", latitude: 51.4858, longitude: -0.1238),
    Station(crs: "VIC", displayName: "Victoria", latitude: 51.4965, longitude: -0.1447),
    Station(crs: "WAT", displayName: "Waterloo", latitude: 51.5033, longitude: -0.1147),
    Station(crs: "WAE", displayName: "Waterloo East", latitude: 51.5046, longitude: -0.1086),
  ]

  /// Known coordinates to support "Near Me" for commonly used stations.
  /// Used as a fallback when the API stop feed does not include geodata.
  private static let knownCoordinates: [String: (Double, Double)] = [
    "BFR": (51.5116, -0.1033),
    "CST": (51.5114, -0.0904),
    "CHX": (51.5070, -0.1247),
    "CTK": (51.5142, -0.1036),
    "EUS": (51.5282, -0.1337),
    "FST": (51.5115, -0.0789),
    "KGX": (51.5308, -0.1238),
    "LST": (51.5178, -0.0823),
    "LBG": (51.5052, -0.0861),
    "MYB": (51.5225, -0.1636),
    "MOG": (51.5185, -0.0887),
    "OLD": (51.5263, -0.0873),
    "PAD": (51.5152, -0.1754),
    "STP": (51.5319, -0.1264),
    "VXH": (51.4858, -0.1238),
    "VIC": (51.4965, -0.1447),
    "WAT": (51.5033, -0.1147),
    "WAE": (51.5046, -0.1086),
    "BHM": (52.4782, -1.8989),
    "BHI": (52.4505, -1.7256),
    "WVH": (52.5870, -2.1196),
    "WSL": (52.5850, -1.9848),
  ]
}
