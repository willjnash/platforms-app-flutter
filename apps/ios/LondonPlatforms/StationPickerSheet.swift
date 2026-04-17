import SwiftUI
import CoreLocation
import MapKit

struct StationPickerSheet: View {
  @Environment(\.dismiss) private var dismiss

  var selectedCRS: String
  var onPick: (Station) -> Void
  var title: String = L10n.stationTitle

  @State private var searchText = ""
  @StateObject private var nearMe = NearMeLocationManager()

  private var filteredStations: [Station] {
    let all = StationCatalog.stations
    let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
      return all
    }
    let query = trimmed.lowercased()
    let candidates = all.filter { station in
      let name = station.displayName.lowercased()
      let crs = station.crs.lowercased()
      return name.hasPrefix(query) || crs.hasPrefix(query)
    }
    guard query.count == 3,
          let exact = candidates.first(where: { $0.crs.lowercased() == query }) else {
      return candidates
    }
    let rest = candidates.filter { $0.crs.lowercased() != query }
    return [exact] + rest
  }

  var body: some View {
    NavigationStack {
      List {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          nearMeSection
        }

        Section {
          ForEach(filteredStations) { station in
            stationRow(station)
          }
        }
      }
      .listStyle(.insetGrouped)
      .navigationTitle(title)
      .navigationBarTitleDisplayMode(.inline)
      .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(L10n.cancel, role: .cancel) { dismiss() }
        }
      }
    }
    .presentationDragIndicator(.visible)
    .presentationDetents([.medium, .large])
  }

  private var nearMeSection: some View {
    Section {
      Button {
        nearMe.requestLocation()
      } label: {
        HStack(spacing: 10) {
          Image(systemName: "location.fill")
            .foregroundStyle(Color.accentColor)
          Text(L10n.stationNearMeAction)
          Spacer()
          if nearMe.isRequesting {
            ProgressView()
              .controlSize(.small)
          } else {
            Image(systemName: "chevron.right")
              .font(.caption.weight(.semibold))
              .foregroundStyle(.tertiary)
          }
        }
      }
      .tint(.primary)

      if let message = nearMe.userMessage {
        Text(message)
          .font(.footnote)
          .foregroundStyle(.secondary)
      }

      ForEach(nearMe.nearbyStations) { nearby in
        stationRow(nearby.station, subtitle: distanceLabel(for: nearby.distance))
      }
    } header: {
      Text(L10n.stationNearMeSection)
    }
  }

  private func stationRow(_ station: Station, subtitle: String? = nil) -> some View {
    Button {
      onPick(station)
      dismiss()
    } label: {
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text(station.displayName)
          if let subtitle {
            Text(subtitle)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        Spacer()
        if station.crs == selectedCRS {
          Image(systemName: "checkmark")
            .fontWeight(.semibold)
            .foregroundStyle(Color.accentColor)
        }
        Text(station.crs)
          .font(.subheadline)
          .foregroundStyle(.tertiary)
          .monospaced()
      }
      .contentShape(Rectangle())
    }
    .tint(.primary)
  }

  private func distanceLabel(for distance: CLLocationDistance) -> String {
    if distance < 1000 {
      return String(format: L10n.stationNearMeDistanceMeters, Int(distance.rounded()))
    }
    return String(format: L10n.stationNearMeDistanceKilometers, distance / 1000)
  }
}

@MainActor
private final class NearMeLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
  struct NearbyStation: Identifiable {
    let station: Station
    let distance: CLLocationDistance
    var id: String { station.id }
  }

  @Published private(set) var currentLocation: CLLocation?
  @Published private(set) var nearbyStations: [NearbyStation] = []
  @Published private(set) var isRequesting = false
  @Published private(set) var userMessage: String?

  private let manager = CLLocationManager()

  override init() {
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
  }

  func requestLocation() {
    userMessage = nil
    let status = manager.authorizationStatus

    switch status {
    case .notDetermined:
      isRequesting = true
      nearbyStations = []
      manager.requestWhenInUseAuthorization()
    case .authorizedAlways, .authorizedWhenInUse:
      isRequesting = true
      nearbyStations = []
      manager.requestLocation()
    case .denied:
      isRequesting = false
      userMessage = L10n.stationNearMeDenied
    case .restricted:
      isRequesting = false
      userMessage = L10n.stationNearMeRestricted
    @unknown default:
      isRequesting = false
      userMessage = L10n.stationNearMeUnavailable
    }
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    switch manager.authorizationStatus {
    case .authorizedAlways, .authorizedWhenInUse:
      if isRequesting {
        manager.requestLocation()
      }
    case .denied:
      isRequesting = false
      userMessage = L10n.stationNearMeDenied
    case .restricted:
      isRequesting = false
      userMessage = L10n.stationNearMeRestricted
    case .notDetermined:
      break
    @unknown default:
      isRequesting = false
      userMessage = L10n.stationNearMeUnavailable
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    if let location = locations.last {
      currentLocation = location
      Task {
        await refreshNearbyStations(from: location)
      }
    } else {
      isRequesting = false
      userMessage = L10n.stationNearMeUnavailable
    }
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    isRequesting = false
    if let clError = error as? CLError, clError.code == .denied {
      userMessage = L10n.stationNearMeDenied
      return
    }
    userMessage = L10n.stationNearMeUnavailable
  }

  private func refreshNearbyStations(from userLocation: CLLocation) async {
    var nearest: [String: NearbyStation] = [:]

    // First use embedded coordinates when available.
    for nearby in StationCatalog.nearestStations(to: userLocation, limit: 20) {
      nearest[nearby.station.crs] = NearbyStation(station: nearby.station, distance: nearby.distance)
    }

    // Then enrich with Apple Maps local search to avoid London-only fallback.
    do {
      let mapStations = try await nearbyStationsFromMapSearch(userLocation: userLocation)
      for item in mapStations {
        let existing = nearest[item.station.crs]
        if existing == nil || item.distance < existing!.distance {
          nearest[item.station.crs] = item
        }
      }
    } catch {
      // Keep coordinate-based fallback list if Maps lookup fails.
    }

    nearbyStations = nearest.values
      .sorted { $0.distance < $1.distance }
      .prefix(8)
      .map { $0 }
    isRequesting = false
    userMessage = nearbyStations.isEmpty ? L10n.stationNearMeUnavailable : nil
  }

  private func nearbyStationsFromMapSearch(userLocation: CLLocation) async throws -> [NearbyStation] {
    var request = MKLocalSearch.Request()
    request.naturalLanguageQuery = "railway station"
    request.region = MKCoordinateRegion(
      center: userLocation.coordinate,
      latitudinalMeters: 50000,
      longitudinalMeters: 50000
    )

    let response = try await MKLocalSearch(request: request).start()
    let catalog = StationCatalog.stations
    var output: [NearbyStation] = []

    for item in response.mapItems {
      guard let name = item.name,
            let itemLocation = item.placemark.location,
            let station = Self.matchStation(name: name, catalog: catalog) else {
        continue
      }
      output.append(
        NearbyStation(station: station, distance: userLocation.distance(from: itemLocation))
      )
    }
    return output
  }

  private static func matchStation(name: String, catalog: [Station]) -> Station? {
    let query = normalizeStationName(name)
    guard !query.isEmpty else { return nil }

    var best: (station: Station, score: Int)?
    for station in catalog {
      let candidate = normalizeStationName(station.displayName)
      let score: Int
      if candidate == query {
        score = 100
      } else if candidate.contains(query) || query.contains(candidate) {
        score = 75
      } else if candidate.replacingOccurrences(of: " ", with: "") == query.replacingOccurrences(of: " ", with: "") {
        score = 70
      } else {
        continue
      }

      if best == nil || score > best!.score {
        best = (station, score)
      }
    }
    return best?.station
  }

  private static func normalizeStationName(_ value: String) -> String {
    value
      .lowercased()
      .replacingOccurrences(of: " railway station", with: "")
      .replacingOccurrences(of: " train station", with: "")
      .replacingOccurrences(of: " station", with: "")
      .replacingOccurrences(of: " (domestic)", with: "")
      .replacingOccurrences(of: "-", with: " ")
      .replacingOccurrences(of: "'", with: "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
