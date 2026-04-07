import Foundation

struct Station: Hashable, Identifiable {
  var id: String { crs }
  let crs: String
  let displayName: String
}

enum StationCatalog {
  /// Matches [docs/SERVICE_SPEC.md](../../docs/SERVICE_SPEC.md) §2.5.
  static let stations: [Station] = [
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

  static func station(crs: String) -> Station {
    stations.first { $0.crs == crs } ?? Station(crs: "EUS", displayName: "Euston")
  }
}
